import 'dart:html';

import 'package:angular/angular.dart';
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
  styleUrls: ["pages.css"]
)
class Page5 {}
