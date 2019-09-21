import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:blood_drive_scheduler/app_component.template.dart' as ng;
import 'package:service_worker/window.dart' as sw;

import 'main.template.dart' as self;

@GenerateInjector([
  routerProvidersHash,
])
final InjectorFactory injector = self.injector$Injector;

void main() {
  /*if (sw.isSupported) {
    sw.register("sw.dart.js");
  }*/
  runApp(ng.AppComponentNgFactory, createInjector: injector);
}
