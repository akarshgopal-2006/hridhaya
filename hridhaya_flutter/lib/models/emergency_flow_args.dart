import '../services/thud_detection_service.dart';

class SafetyLoopArgs {
  final String trigger;
  final ThudEvent? thudEvent;

  const SafetyLoopArgs._(this.trigger, {this.thudEvent});

  const SafetyLoopArgs.manual() : this._('manual');
  const SafetyLoopArgs.testThud() : this._('test_thud');
  const SafetyLoopArgs.autoThud(ThudEvent event)
      : this._('auto_thud', thudEvent: event);
}

class BystanderArgs {
  final String? incidentId;
  const BystanderArgs({this.incidentId});
}

