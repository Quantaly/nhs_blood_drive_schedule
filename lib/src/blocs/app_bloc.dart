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
  List<List<dynamic>> get scheduleCsv;

  // page 4
  @nullable
  @BuiltValueField(serialize: false)
  List<List<dynamic>> get signupCsv;

  AppInput._();
  factory AppInput([void Function(AppInputBuilder) updates]) = _$AppInput;
}

void initialAppState(AppStateBuilder b) => b
  ..page = 1
  ..canAdvance = true
  ..canRegress = false
  ..processing = false
  ..processingBlurb = ""
  ..serializeState = true
  ..input.update((b) => b);

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
  AppState get initialState =>
      _serializer.loadState() ?? AppState(initialAppState);

  @override
  Stream<AppState> mapEventToState(AppEvent event) async* {
    var previousState = currentState;

    if (event is UpdateEvent) {
      var newInput = previousState.input.rebuild(event.updates);
      yield previousState.rebuild((b) => b
        ..canAdvance = canAdvance(previousState.page, newInput)
        ..serializeState = true
        ..input.replace(newInput));

      //
    } else if (event is AdvanceEvent) {
      if (previousState.canAdvance) {
        switch (previousState.page) {
          case 1:
          case 2:
            break;
        }
        yield previousState.rebuild((b) => b
          ..page = previousState.page + 1
          ..canAdvance = canAdvance(previousState.page + 1, previousState.input)
          ..canRegress = canRegress(previousState.page + 1, previousState.input)
          ..processing = false
          ..processingBlurb = ""
          ..serializeState = true);
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
    super.onTransition(transition);
    print(transition);
    if (transition.nextState.serializeState) {
      _serializer.saveState(transition.nextState);
    }
  }

  static bool canAdvance(int page, AppInput input) {
    switch (page) {
      case 1:
        return true;
      case 2:
        return false;
      default:
        return false;
    }
  }

  static bool canRegress(int page, AppInput input) => page > 1;
}
