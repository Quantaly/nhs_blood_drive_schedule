import 'app_states.dart';

abstract class AppEvent {}

class UpdateEvent implements AppEvent {
  final void Function(AppInputBuilder) updates;
  UpdateEvent(this.updates);
}

class AdvanceEvent implements AppEvent {}

class RegressEvent implements AppEvent {}

class JumpEvent implements AppEvent {
  final int page;
  JumpEvent(this.page);
}

class ResetEvent implements AppEvent {}