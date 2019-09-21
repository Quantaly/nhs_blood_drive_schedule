import 'dart:async';
import 'dart:html';

import 'package:angular/angular.dart';

@Component(
  selector: "bd-pwa-prompt",
  templateUrl: "pwa_prompt.html",
  styleUrls: ["pwa_prompt.css"],
  directives: [coreDirectives],
)
class PwaPrompt implements OnInit, OnDestroy {
  StreamSubscription<BeforeInstallPromptEvent> _subscription;
  BeforeInstallPromptEvent event;

  static const _dismissedKey = "bd-dismissed";
  bool _dismissedCache = window.localStorage.containsKey(_dismissedKey);
  bool get dismissed => _dismissedCache;
  set dismissed(bool value) {
    _dismissedCache = value;
    if (value) {
      window.localStorage[_dismissedKey] = "f";
    } else {
      window.localStorage.remove(_dismissedKey);
    }
  }

  @override
  void ngOnInit() {
    _subscription = window.on["beforeinstallprompt"]
        .cast<BeforeInstallPromptEvent>()
        .listen((evt) {
      evt.preventDefault();
      if (!dismissed) {
        event = evt;
        evt.userChoice.then((_) => event = null);
      }
    });
  }

  void yes() {
    if (event != null && !dismissed) {
      event.prompt();
    }
  }

  void no() {
    _subscription?.cancel();
    _subscription = null;
    event = null;
    dismissed = true;
  }

  @override
  void ngOnDestroy() {
    _subscription?.cancel();
    _subscription = null;
  }
}
