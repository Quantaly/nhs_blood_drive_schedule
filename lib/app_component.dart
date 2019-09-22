import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';

import 'src/blocs/app_bloc.dart';
import 'src/components/pwa_prompt/pwa_prompt.dart';
import 'src/routing.dart';
import 'src/services/reset_confirm_service.dart';
import 'src/services/state_serialization.dart';

@Component(
  selector: "bd-app",
  templateUrl: "app_component.html",
  styleUrls: ["app_component.css"],
  directives: [routerDirectives, PwaPrompt],
  providers: [
    ClassProvider(AppBloc),
    ClassProvider(ResetConfirmService),
    ClassProvider(StateSerializationService),
  ],
  exports: [Routes],
)
class AppComponent implements OnInit {
  final AppBloc bloc;
  final Router _router;
  AppComponent(this.bloc, this._router);

  String notification = "";
  AppState get state => bloc.currentState;

  @override
  void ngOnInit() {
    bloc.state.listen((state) {
      _router.navigate("/${state.page}");
      notification = state.processingBlurb.isNotEmpty
          ? state.processingBlurb
          : "Page ${state.page}";
    });
    _router.onRouteActivated.listen((route) {
      if (route.routePath.additionalData != state.page) {
        _router.navigate("/${state.page}");
      };
    });
  }

  void advance() => bloc.dispatch(AdvanceEvent());
  void regress() => bloc.dispatch(RegressEvent());
  void reset() => bloc.dispatch(ResetEvent());
}
