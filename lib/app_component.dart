import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';

import 'src/routing.dart';

@Component(
  selector: "bd-app",
  templateUrl: "app_component.html",
  styleUrls: ["app_component.css"],
  directives: [routerDirectives],
  exports: [Routes],
)
class AppComponent {
  final Router _router;
  AppComponent(this._router);

  int get currentPage => _router.current?.routePath?.additionalData ?? 0;

  bool get canAdvance {
    if (_router.current == null) {
      return false;
    }
    return _router.current.routePath.additionalData < Routes.routes.length;
  }

  void advance() {
    _router.navigate("/${currentPage + 1}");
  }

  bool get canRegress {
    if (_router.current == null) {
      return false;
    }
    return _router.current.routePath.additionalData > 1;
  }

  void regress() {
    _router.navigate("/${currentPage - 1}");
  }

  void reset() {
    if (window
        .confirm("Start over from the beginning and lose all progress?")) {
      _router.navigate("/1");
    }
  }
}
