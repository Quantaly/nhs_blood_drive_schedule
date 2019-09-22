import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular/security.dart';
import 'package:csv/csv.dart';

import '../../blocs/app_bloc.dart';
import '../explainer/explainer.dart';

// Blood Drive Schedule Generator
@Component(
  selector: "bd-page1",
  templateUrl: "page1.html",
  styleUrls: ["pages.css"],
)
class Page1 {}

// Notes on CSV files
@Component(
  selector: "bd-page2",
  templateUrl: "page2.html",
  styleUrls: ["pages.css"],
  directives: [Explainer],
)
class Page2 {
  static const excelSteps = [
    "Open the file in MS Excel",
    "Press <strong>F12 (Save As)</strong>",
    "Choose <strong>CSV (comma delimited) (*.csv)</strong> from the \"Save as type\" dropdown",
    "Enter a name and save the file",
    "If a warning box pops up, press <strong>OK</strong>"
  ];

  static const sheetsSteps = [
    "Open the file in Google Sheets",
    "Open the <strong>File</strong> menu",
    "Under <strong>Download</strong>, choose <strong>Comma-separated values (.csv, current sheet)</strong>"
  ];
}

final csvReader = CsvToListConverter();

// Import student schedules
@Component(
  selector: "bd-page3",
  templateUrl: "page3.html",
  styleUrls: ["pages.css"],
  directives: [coreDirectives],
)
class Page3 {
  AppBloc bloc;
  Page3(this.bloc);

  bool displayProcessing = false;
  AppState get state => bloc.currentState;

  void processImport(File csvFile) {
    displayProcessing = true;
    var reader = FileReader();
    reader.readAsText(csvFile);
    reader.onLoadEnd.first.then((_) async {
      var table = csvReader.convert(reader.result);
      bloc.dispatch(UpdateEvent((b) => b.scheduleCsv.csvContent = table));
    });
  }

  void updateIdCol(String index) {
    bloc.dispatch(UpdateEvent((b) => b.scheduleCsv.idCol = int.parse(index)));
  }

  void updateClassCol(String index) {
    bloc.dispatch(
        UpdateEvent((b) => b.scheduleCsv.classCol = int.parse(index)));
  }

  void updatePeriodCol(String index) {
    bloc.dispatch(
        UpdateEvent((b) => b.scheduleCsv.periodCol = int.parse(index)));
  }
}

// Import signups
@Component(
  selector: "bd-page4",
  templateUrl: "page4.html",
  styleUrls: ["pages.css"],
  directives: [coreDirectives],
)
class Page4 {
  AppBloc bloc;
  Page4(this.bloc);

  bool displayProcessing = false;
  AppState get state => bloc.currentState;

  void processImport(File csvFile) {
    displayProcessing = true;
    var reader = FileReader();
    reader.readAsText(csvFile);
    reader.onLoadEnd.first.then((_) async {
      var table = csvReader.convert(reader.result);
      bloc.dispatch(UpdateEvent((b) => b.signupCsv.csvContent = table));
    });
  }

  void updateIdCol(String index) {
    bloc.dispatch(UpdateEvent((b) => b.signupCsv.idCol = int.parse(index)));
  }
}

@Component(
  selector: "bd-page5",
  templateUrl: "page5.html",
  styleUrls: ["pages.css"],
  directives: [coreDirectives],
)
class Page5 implements OnInit {
  AppBloc bloc;
  Page5(this.bloc);

  AppState get state => bloc.currentState;

  RadioButtonInputElement rCast(EventTarget t) => t as RadioButtonInputElement;

  String _selected;
  String get selected => _selected;
  set selected(String value) {
    _selected = value;
    switch (value) {
      case "odd":
        bloc.dispatch(UpdateEvent((b) => b.availablePeriods
          ..p1 = true
          ..p3 = true
          ..p5 = true
          ..p7 = true
          ..p2 = false
          ..p4 = false
          ..p6 = false
          ..p8 = false));
        break;
      case "even":
        bloc.dispatch(UpdateEvent((b) => b.availablePeriods
          ..p2 = true
          ..p4 = true
          ..p6 = true
          ..p8 = true
          ..p1 = false
          ..p3 = false
          ..p5 = false
          ..p7 = false));
        break;
      case "fri":
        bloc.dispatch(UpdateEvent((b) => b.availablePeriods
          ..p1 = true
          ..p2 = true
          ..p3 = true
          ..p4 = true
          ..p5 = true
          ..p6 = true
          ..p7 = true
          ..p8 = true));
        break;
    }
  }

  @override
  void ngOnInit() {
    var p = state.input.availablePeriods;
    if (p.p1 && p.p3 && p.p5 && p.p7 && !p.p2 && !p.p4 && !p.p6 && !p.p8) {
      _selected = "odd";
    } else if (p.p2 &&
        p.p4 &&
        p.p6 &&
        p.p8 &&
        !p.p1 &&
        !p.p3 &&
        !p.p5 &&
        !p.p7) {
      _selected = "even";
    } else if (p.p1 && p.p2 && p.p3 && p.p4 && p.p5 && p.p6 && p.p7 && p.p8) {
      _selected = "fri";
    } else if (p.p1 || p.p2 || p.p3 || p.p4 || p.p5 || p.p6 || p.p7 || p.p8) {
      _selected = "custom";
    }
  }

  void toggle1() => bloc.dispatch(UpdateEvent(
      (b) => b.availablePeriods.p1 = !state.input.availablePeriods.p1));
  void toggle2() => bloc.dispatch(UpdateEvent(
      (b) => b.availablePeriods.p2 = !state.input.availablePeriods.p2));
  void toggle3() => bloc.dispatch(UpdateEvent(
      (b) => b.availablePeriods.p3 = !state.input.availablePeriods.p3));
  void toggle4() => bloc.dispatch(UpdateEvent(
      (b) => b.availablePeriods.p4 = !state.input.availablePeriods.p4));
  void toggle5() => bloc.dispatch(UpdateEvent(
      (b) => b.availablePeriods.p5 = !state.input.availablePeriods.p5));
  void toggle6() => bloc.dispatch(UpdateEvent(
      (b) => b.availablePeriods.p6 = !state.input.availablePeriods.p6));
  void toggle7() => bloc.dispatch(UpdateEvent(
      (b) => b.availablePeriods.p7 = !state.input.availablePeriods.p7));
  void toggle8() => bloc.dispatch(UpdateEvent(
      (b) => b.availablePeriods.p8 = !state.input.availablePeriods.p8));
}

@Component(
  selector: "bd-page6",
  templateUrl: "page6.html",
  styleUrls: ["pages.css"],
  directives: [coreDirectives],
)
class Page6 {
  AppBloc bloc;
  Page6(this.bloc);

  AppState get state => bloc.currentState;

  void prioritize(String key, int value) =>
      bloc.dispatch(UpdateEvent((b) => b.classPriorityMap[key] = value));
}

@Component(
  selector: "bd-page7",
  templateUrl: "page7.html",
  styleUrls: ["pages.css"],
)
class Page7 {}

@Component(
  selector: "bd-page8",
  templateUrl: "page8.html",
  styleUrls: ["pages.css"],
)
class Page8 {
  final AppBloc bloc;
  final DomSanitizationService sanitizer;
  Page8(this.bloc, this.sanitizer);

  Object get dataUrl =>
      sanitizer.bypassSecurityTrustUrl(bloc.currentState.finalOutputDataUrl);
}
