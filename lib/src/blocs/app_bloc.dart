import 'dart:async';

import 'package:bloc/bloc.dart';

import '../services/reset_confirm_service.dart';
import '../services/state_serialization.dart';
import 'app_events.dart';
import 'app_states.dart';

export 'app_events.dart';
export 'app_states.dart';

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
                ..processingBlurb = "Indexing..."
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
                ..processingBlurb = "Indexing..."
                ..serializeState = false);
              var csvTable = newInput.signupCsv.csvContent;
              await _serializer.indexSignups(
                  csvTable, newInput.signupCsv.idCol);
              newInput = newInput.rebuild((b) => b
                ..signupCsv = null
                ..hasIndexedSignup = true);
            }
            break;

          case 5:
            yield previousState.rebuild((b) => b
              ..processing = true
              ..processingBlurb = "Filtering..."
              ..serializeState = false);
            var classes = await _serializer
                .getApplicableClasses(newInput.availablePeriods.toStringSet());
            var priorityMap = await _serializer.getClassPriorities(classes,
                defaultPriority: 1);
            newInput = newInput.rebuild((b) => b.classPriorityMap
              ..clear()
              ..addAll(priorityMap));
            break;

          case 6:
            yield previousState.rebuild((b) => b
              ..processing = true
              ..processingBlurb = "Updating..."
              ..serializeState = false);
            await _serializer
                .saveClassPriorities(newInput.classPriorityMap.asMap());
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
      case 6:
        return true;
      default:
        return false;
    }
  }

  static bool canRegress(int page, AppInput input) => page > 1;

  static int orElse(int input, int defaultValue) =>
      input == -1 ? defaultValue : input;
}
