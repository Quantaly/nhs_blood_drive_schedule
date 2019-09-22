import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';

import 'blocs/app_states.dart';

part 'serializers.g.dart';

@SerializersFor([
  AppState,
  AppInput,
])
final Serializers serializers = _$serializers;
