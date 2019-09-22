import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'dart:indexed_db';

import '../blocs/app_bloc.dart';
import '../serializers.dart';

class StateSerializationService {
  static const _stateKey = "bd-serState";
  static const _dbName = "bd-database";
  static const _schedulesKey = "bd-schedules";
  static const _signupsKey = "bd-signups";
  static const _classPrioritiesKey = "bd-classPriorities";

  Future<Database> _dbFuture = _open();

  AppState loadState() {
    var serialized = window.localStorage[_stateKey];
    if (serialized == null) {
      return null;
    } else {
      return serializers.deserializeWith(
          AppState.serializer, jsonDecode(serialized));
    }
  }

  void saveState(AppState state) {
    window.localStorage[_stateKey] =
        jsonEncode(serializers.serializeWith(AppState.serializer, state));
  }

  Future<void> indexSchedules(
      List<List<Object>> table, int idCol, int classCol, int periodCol) async {
    var db = await _dbFuture;
    var schedulesStore =
        db.transaction(_schedulesKey, "readwrite").objectStore(_schedulesKey);
    await schedulesStore.clear();
    await Future.wait([
      for (var row in table.skip(1))
        schedulesStore.put({
          "id": row[idCol],
          "class": row[classCol],
          "period": row[periodCol],
          "rawCsv": row,
        })
    ]);
  }

  Future<void> indexSignups(List<List<Object>> table, int idCol) async {
    var db = await _dbFuture;
    var signupsStore =
        db.transaction(_signupsKey, "readwrite").objectStore(_signupsKey);
    await signupsStore.clear();
    await Future.wait([
      for (var row in table.skip(1))
        signupsStore.put({
          "id": row[idCol],
          "rawCsv": row,
        })
    ]);
  }

  Future<Set<String>> getApplicableClasses(Set<String> periods) async {
    var db = await _dbFuture;
    var txn = db.transaction([_schedulesKey, _signupsKey], "readonly");
    var schedulesStore = txn.objectStore(_schedulesKey);
    var signupsStore = txn.objectStore(_signupsKey);

    Set<int> signupIds = (await _requestToFuture(
                signupsStore.index("id").getAll(KeyRange.lowerBound(1111111)))
            as List)
        .cast<Map>()
        .map((m) => m["id"])
        .whereType<int>()
        .toSet();

    Set<String> ret = {};
    await for (var cursor in schedulesStore.openCursor()) {
      var val = (cursor.value as Map).cast<String, Object>();
      if (signupIds.contains(val["id"]) && periods.contains(val["period"])) {
        ret.add(val["class"]);
      }
      cursor.next();
    }

    print("getApplicableClasses: $ret");
    return ret;
  }

  Future<Map<String, int>> getClassPriorities(Iterable<String> classes,
      {int defaultPriority}) async {
    var db = await _dbFuture;
    var prioritiesStore = db
        .transaction(_classPrioritiesKey, "readonly")
        .objectStore(_classPrioritiesKey);
    Map<String, int> ret = {};
    await Future.wait([
      for (var clazz in classes)
        prioritiesStore
            .getObject(clazz)
            .then((pri) => ret[clazz] = pri ?? defaultPriority)
    ]);
    return ret;
  }

  Future<int> getPriorityForClass(String clazz, {int defaultPriority}) async {
    var db = await _dbFuture;
    var prioritiesStore = db
        .transaction(_classPrioritiesKey, "readonly")
        .objectStore(_classPrioritiesKey);
    return await prioritiesStore.getObject(clazz) ?? defaultPriority;
  }

  Future<void> saveClassPriorities(Map<String, int> priorities) async {
    var db = await _dbFuture;
    var prioritiesStore = db
        .transaction(_classPrioritiesKey, "readwrite")
        .objectStore(_classPrioritiesKey);
    await Future.wait([
      for (var entry in priorities.entries)
        prioritiesStore.put(entry.value, entry.key)
    ]);
  }

  Future<Map<int, Set<StructuredSchedule>>> loadSchedulesForSignups() async {
    var db = await _dbFuture;
    var txn = db.transaction([_schedulesKey, _signupsKey], "readonly");
    var schedulesStore = txn.objectStore(_schedulesKey);
    var signupsStore = txn.objectStore(_signupsKey);

    Set<int> signupIds = (await _requestToFuture(
                signupsStore.index("id").getAll(KeyRange.lowerBound(1111111)))
            as List)
        .cast<Map>()
        .map((m) => m["id"])
        .whereType<int>()
        .toSet();

    Map<int, Set<StructuredSchedule>> ret = {};
    for (var id in signupIds) {
      Set<StructuredSchedule> schedules = {};
      await for (var cursor in schedulesStore.index("id").openCursor(key: id)) {
        Map value = cursor.value;
        schedules.add(StructuredSchedule(
            id: value["id"],
            clazz: value["class"],
            period: value["period"],
            rawCsv: value["rawCsv"]));
        cursor.next();
      }
      ret[id] = schedules;
    }

    return ret;
  }

  // only class priorities should persist
  Future<void> clearSession() async {
    window.localStorage.remove(_stateKey);

    var db = await _dbFuture;
    var txn = db.transaction([_schedulesKey, _signupsKey], "readwrite");
    var schedulesStore = txn.objectStore(_schedulesKey);
    var signupsStore = txn.objectStore(_signupsKey);

    await Future.wait([
      schedulesStore.clear(),
      signupsStore.clear(),
    ]);
  }

  static Future _requestToFuture(Request request) {
    Completer ret = Completer();
    StreamSubscription valSub, errSub;
    valSub = request.onSuccess.listen((_) {
      valSub.cancel();
      errSub.cancel();
      ret.complete(request.result);
    });
    errSub = request.onError.listen((_) {
      valSub.cancel();
      errSub.cancel();
      ret.completeError(request.error);
    });
    return ret.future;
  }

  static Future<Database> _open() => window.indexedDB.open(
        _dbName,
        version: 1,
        onUpgradeNeeded: (evt) {
          Database db = evt.target.result;
          upgradeLoop:
          for (var currentVersion = evt.oldVersion;
              currentVersion < evt.newVersion;
              currentVersion++) {
            switch (currentVersion) {
              case 0:
                var scheduleStore =
                    db.createObjectStore(_schedulesKey, autoIncrement: true);
                scheduleStore.createIndex("id", "id");
                var signupsStore =
                    db.createObjectStore(_signupsKey, autoIncrement: true);
                signupsStore.createIndex("id", "id");
                db.createObjectStore(_classPrioritiesKey);
                break;

              default:
                // should never get here
                break upgradeLoop;
            }
          }
        },
      );
}

class StructuredSchedule {
  final int id;
  final String clazz;
  final String period;
  final List<Object> rawCsv;
  StructuredSchedule({this.id, this.clazz, this.period, this.rawCsv});
}

class StructuredSignup {
  final int id;
  final List<Object> rawCsv;
  StructuredSignup({this.id, this.rawCsv});
}
