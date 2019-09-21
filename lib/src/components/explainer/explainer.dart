import 'package:angular/angular.dart';

@Component(
  selector: "bd-explain",
  templateUrl: "explainer.html",
  styleUrls: ["explainer.css"],
  directives: [coreDirectives],
)
class Explainer {
  @Input()
  String name;

  @Input()
  List<String> steps;

  bool expanded = false;

  String get icon => expanded ? "expand_less" : "expand_more";
  String get buttonHint => expanded ? "Collapse $name" : "Expand $name";
}
