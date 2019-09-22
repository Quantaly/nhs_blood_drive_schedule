import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'app_states.g.dart';

abstract class AppState implements Built<AppState, AppStateBuilder> {
  static Serializer<AppState> get serializer => _$appStateSerializer;

  int get page;
  bool get canAdvance;
  bool get canRegress;

  bool get processing;
  String get processingBlurb;

  bool get serializeState;

  AppInput get input;

  String get finalOutputDataUrl;

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

  // page 6
  BuiltMap<String, int> get classPriorityMap;

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
      ..p8 = false)
    ..classPriorityMap.clear())
  ..finalOutputDataUrl = "";
