import 'dart:html';

class ResetConfirmService {
  bool confirmReset() =>
      window.confirm("Start over from the beginning and lose all progress?");
  
  bool call() => confirmReset();
}
