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
