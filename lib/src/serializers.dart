import 'package:built_value/serializer.dart';

import 'blocs/app_bloc.dart';

part 'serializers.g.dart';

@SerializersFor([
  AppState,
  AppInput,
])
final Serializers serializers = _$serializers;
