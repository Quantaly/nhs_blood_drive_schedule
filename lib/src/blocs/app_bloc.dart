import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

import '../services/reset_confirm_service.dart';
import '../services/state_serialization.dart';

part 'app_bloc.g.dart';

abstract class AppState implements Built<AppState, AppStateBuilder> {
  static Serializer<AppState> get serializer => _$appStateSerializer;

  int get page;
  bool get canAdvance;
  bool get canRegress;

  bool get processing;
  String get processingBlurb;

  bool get serializeState;

  AppInput get input;

  AppState._();
  factory AppState([void Function(AppStateBuilder) updates]) = _$AppState;
}

abstract class AppInput implements Built<AppInput, AppInputBuilder> {
  static Serializer<AppInput> get serializer => _$appInputSerializer;

  // page 3
  @nullable
  @BuiltValueField(serialize: false)
  CsvImportStatus get scheduleCsv;
  bool get hasIndexedSchedule;

  // page 4
  @nullable
  @BuiltValueField(serialize: false)
  CsvImportStatus get signupCsv;
  bool get hasIndexedSignup;

  // page 5
  PeriodSet get availablePeriods;

  AppInput._();
  factory AppInput([void Function(AppInputBuilder) updates]) = _$AppInput;
}

abstract class CsvImportStatus
    implements Built<CsvImportStatus, CsvImportStatusBuilder> {
  List<List<Object>> get csvContent;

  @nullable
  List<String> get headers;

  @nullable
  int get idCol;

  @nullable
  int get classCol;

  @nullable
  int get periodCol;

  CsvImportStatus._();
  factory CsvImportStatus([void Function(CsvImportStatusBuilder) updates]) =
      _$CsvImportStatus;
}

abstract class PeriodSet implements Built<PeriodSet, PeriodSetBuilder> {
  static Serializer<PeriodSet> get serializer => _$periodSetSerializer;

  bool get p1;
  bool get p2;
  bool get p3;
  bool get p4;
  bool get p5;
  bool get p6;
  bool get p7;
  bool get p8;

  Set<String> toStringSet() => {
        if (p1) "P1",
        if (p2) "P2",
        if (p3) "P3",
        if (p4) "P4",
        if (p5) "P5",
        if (p6) "P6",
        if (p7) "P7",
        if (p8) "P8",
      };

  PeriodSet._();
  factory PeriodSet([void Function(PeriodSetBuilder) updates]) = _$PeriodSet;
}

void initialAppState(AppStateBuilder b) => b
  ..page = 1
  ..canAdvance = true
  ..canRegress = false
  ..processing = false
  ..processingBlurb = ""
  ..serializeState = true
  ..input.update((b) => b
    ..hasIndexedSchedule = false
    ..hasIndexedSignup = false
    ..availablePeriods.update((b) => b
      ..p1 = false
      ..p2 = false
      ..p3 = false
      ..p4 = false
      ..p5 = false
      ..p6 = false
      ..p7 = false
      ..p8 = false));

abstract class AppEvent {}

class UpdateEvent implements AppEvent {
  final void Function(AppInputBuilder) updates;
  UpdateEvent(this.updates);
}

class AdvanceEvent implements AppEvent {}

class RegressEvent implements AppEvent {}

class JumpEvent implements AppEvent {
  final int page;
  JumpEvent(this.page);
}

class ResetEvent implements AppEvent {}

class AppBloc extends Bloc<AppEvent, AppState> {
  final StateSerializationService _serializer;
  final ResetConfirmService _confirmReset;
  AppBloc(this._serializer, this._confirmReset);

  @override
  AppState get initialState {
    var loaded = _serializer.loadState() ?? AppState(initialAppState);
    return loaded.rebuild((b) => b
      ..canAdvance = canAdvance(loaded.page, loaded.input)
      ..canRegress = canRegress(loaded.page, loaded.input));
  }

  @override
  Stream<AppState> mapEventToState(AppEvent event) async* {
    var previousState = currentState;

    if (event is UpdateEvent) {
      var newInput = previousState.input.rebuild(event.updates);

      // handle csv defaults
      if (newInput.scheduleCsv != null &&
          newInput.scheduleCsv.headers == null) {
        var headers =
            newInput.scheduleCsv.csvContent[0].map((s) => "$s").toList();
        var idCol = orElse(headers.indexWhere((s) => s.contains("ID")), 0);
        var classCol =
            orElse(headers.indexWhere((s) => s.contains("Class")), 3);
        var periodCol = orElse(
            headers.indexWhere((s) => s.contains("Period")), classCol + 1);
        newInput = newInput.rebuild((b) => b
          ..scheduleCsv.update((b) => b
            ..headers = headers
            ..idCol = idCol
            ..classCol = classCol
            ..periodCol = periodCol));
      }
      if (newInput.signupCsv != null && newInput.signupCsv.headers == null) {
        var headers =
            newInput.signupCsv.csvContent[0].map((s) => "$s").toList();
        var idCol = orElse(headers.indexWhere((s) => s.contains("ID")), 1);
        newInput = newInput.rebuild((b) => b
          ..signupCsv.update((b) => b
            ..headers = headers
            ..idCol = idCol));
      }

      yield previousState.rebuild((b) => b
        ..canAdvance = canAdvance(previousState.page, newInput)
        ..serializeState = true
        ..input.replace(newInput));

      //
    } else if (event is AdvanceEvent) {
      if (previousState.canAdvance) {
        var newInput = previousState.input;
        switch (previousState.page) {
          case 1:
          case 2:
            break;

          case 3:
            if (newInput.scheduleCsv != null) {
              yield previousState.rebuild((b) => b
                ..processing = true
                ..processingBlurb = "Indexing (this may take some time)..."
                ..serializeState = false);
              var csvTable = newInput.scheduleCsv.csvContent;
              await _serializer.indexSchedules(
                  csvTable,
                  newInput.scheduleCsv.idCol,
                  newInput.scheduleCsv.classCol,
                  newInput.scheduleCsv.periodCol);
              newInput = newInput.rebuild((b) => b
                ..scheduleCsv = null
                ..hasIndexedSchedule = true);
            }
            break;

          case 4:
            if (newInput.signupCsv != null) {
              yield previousState.rebuild((b) => b
                ..processing = true
                ..processingBlurb = "Indexing (this may take some time)..."
                ..serializeState = false);
              var csvTable = newInput.signupCsv.csvContent;
              await _serializer.indexSignups(
                  csvTable, newInput.signupCsv.idCol);
              newInput = newInput.rebuild((b) => b
                ..signupCsv = null
                ..hasIndexedSignup = true);
            }
            break;
        }

        yield previousState.rebuild((b) => b
          ..page = previousState.page + 1
          ..canAdvance = canAdvance(previousState.page + 1, previousState.input)
          ..canRegress = canRegress(previousState.page + 1, previousState.input)
          ..processing = false
          ..processingBlurb = ""
          ..serializeState = true
          ..input.replace(newInput));
      }

      //
    } else if (event is RegressEvent) {
      if (previousState.canRegress) {
        yield previousState.rebuild((b) => b
          ..page = previousState.page - 1
          ..canAdvance = canAdvance(previousState.page - 1, previousState.input)
          ..canRegress = canRegress(previousState.page - 1, previousState.input)
          ..processing = false
          ..processingBlurb = ""
          ..serializeState = true);
      }

      //
    } else if (event is JumpEvent) {
      yield previousState.rebuild((b) => b
        ..page = event.page
        ..canAdvance = canAdvance(event.page, previousState.input)
        ..canRegress = canRegress(event.page, previousState.input)
        ..processing = false
        ..processingBlurb = ""
        ..serializeState = true);

      //
    } else if (event is ResetEvent) {
      if (_confirmReset()) {
        yield AppState(initialAppState);
      }
    }
  }

  @override
  void onTransition(Transition<AppEvent, AppState> transition) {
    if (transition.nextState.serializeState) {
      _serializer.saveState(transition.nextState);
    }
  }

  @override
  void onError(Object error, StackTrace stacktrace) {
    print("BLOC ERROR: $error\n$stacktrace");
  }

  static bool canAdvance(int page, AppInput input) {
    switch (page) {
      case 1:
        return true;
      case 2:
        return true;
      case 3:
        return input.hasIndexedSchedule || input.scheduleCsv != null;
      case 4:
        return input.hasIndexedSignup || input.signupCsv != null;
      case 5:
        return input.availablePeriods.toStringSet().isNotEmpty;
      default:
        return false;
    }
  }

  static bool canRegress(int page, AppInput input) => page > 1;

  static int orElse(int input, int defaultValue) =>
      input == -1 ? defaultValue : input;
}
