import 'package:angular/angular.dart';

import '../pwa_prompt/pwa_prompt.dart';

@Component(
  selector: "bd-page1",
  templateUrl: "page1.html",
  styleUrls: ["pages.css"],
  directives: [PwaPrompt],
)
class Page1 {}

@Component(
  selector: "bd-page2",
  templateUrl: "page2.html",
  styleUrls: ["pages.css"],
)
class Page2 {}
