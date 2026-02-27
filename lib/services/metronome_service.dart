import 'dart:async';

import 'package:flutter/services.dart';

class MetronomeTick {
  final DateTime at;
  final int bpm;
  final bool isDownbeat;

  const MetronomeTick({
    required this.at,
    required this.bpm,
    required this.isDownbeat,
  });
}

class MetronomeService {
  final _controller = StreamController<MetronomeTick>.broadcast();
  Timer? _timer;
  int _count = 0;

  Stream<MetronomeTick> get ticks => _controller.stream;

  void start({required int bpm}) {
    stop();
    _count = 0;
    final intervalMs = (60000 / bpm).round();
    _timer = Timer.periodic(Duration(milliseconds: intervalMs), (_) {
      _count++;
      final tick = MetronomeTick(
        at: DateTime.now(),
        bpm: bpm,
        isDownbeat: _count % 4 == 1,
      );
      _controller.add(tick);
      SystemSound.play(SystemSoundType.click);
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> dispose() async {
    stop();
    await _controller.close();
  }
}
