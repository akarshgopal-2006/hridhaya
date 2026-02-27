import '../services/fall_detection_service.dart';

class SafetyLoopArgs {
  final String trigger;
  final FallEvent? fallEvent;

  const SafetyLoopArgs._(this.trigger, {this.fallEvent});

  const SafetyLoopArgs.manual() : this._('manual');
  const SafetyLoopArgs.testFall() : this._('test_fall');
  const SafetyLoopArgs.autoFall(FallEvent event)
      : this._('auto_fall', fallEvent: event);
}

class BystanderArgs {
  final String? incidentId;
  const BystanderArgs({this.incidentId});
}
