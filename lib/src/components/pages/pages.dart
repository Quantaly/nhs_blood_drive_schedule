import 'package:angular/angular.dart';

import '../explainer/explainer.dart';

@Component(
  selector: "bd-page1",
  templateUrl: "page1.html",
  styleUrls: ["pages.css"],
)
class Page1 {}

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
