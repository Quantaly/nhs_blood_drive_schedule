import 'dart:convert';
import 'dart:html';

import '../blocs/app_bloc.dart';
import '../serializers.dart';

class StateSerializationService {
  static const _stateKey = "bd-serState";

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
}
