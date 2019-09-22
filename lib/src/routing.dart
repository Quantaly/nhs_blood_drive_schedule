import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';

import 'components/pages/pages.template.dart' as pages;

class Routes {
  static final templates = <ComponentFactory>[
    pages.Page1NgFactory,
    pages.Page2NgFactory,
    pages.Page3NgFactory,
    pages.Page4NgFactory,
    pages.Page5NgFactory,
    pages.Page6NgFactory,
    pages.Page7NgFactory,
    pages.Page8NgFactory,
  ];

  static final routes = [
    for (var i = 1; i <= templates.length; i++)
      RouteDefinition(
        path: "$i",
        component: templates[i - 1],
        additionalData: i,
        useAsDefault: i == 1,
      )
  ];
}
