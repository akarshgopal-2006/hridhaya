import 'dart:async';

import 'package:flutter/material.dart';

import 'app_controller.dart';
import 'models/emergency_flow_args.dart';
import 'routes.dart';
import 'screens/bystander_command_center_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/digital_stethoscope_screen.dart';
import 'screens/loading_screen.dart';
import 'screens/safety_loop_screen.dart';
import 'screens/settings_privacy_screen.dart';
import 'screens/sos_screen.dart';
import 'screens/doctor_consult_screen.dart';
import 'screens/chatbot_screen.dart';
import 'screens/map_screen.dart';
import 'screens/payment_screen.dart';
import 'theme/app_theme.dart';

final _navKey = GlobalKey<NavigatorState>();

class HridhayaApp extends StatefulWidget {
  const HridhayaApp({super.key});

  @override
  State<HridhayaApp> createState() => _HridhayaAppState();
}

class _HridhayaAppState extends State<HridhayaApp> {
  final AppController _controller = AppController();
  StreamSubscription? _fallSub;
  late final Future<void> _initFuture = _controller.init();
  bool _safetyLoopOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fallSub = _controller.fallEvents.listen((event) {
        final nav = _navKey.currentState;
        if (nav == null) return;

        if (_safetyLoopOpen) return;
        _safetyLoopOpen = true;
        nav
            .pushNamed(
              Routes.safetyLoop,
              arguments: SafetyLoopArgs.autoFall(event),
            )
            .whenComplete(() {
          _safetyLoopOpen = false;
        });
      });
    });
  }

  @override
  void dispose() {
    _fallSub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snap) {
        return AppScope(
          controller: _controller,
          child: MaterialApp(
            navigatorKey: _navKey,
            debugShowCheckedModeBanner: false,
            title: 'Hridhaya',
            theme: AppTheme.light(),
            initialRoute: Routes.dashboard,
            onGenerateRoute: (settings) {
              switch (settings.name) {
                case Routes.loading:
                  return MaterialPageRoute(
                    settings: settings,
                    builder: (_) => const LoadingScreen(),
                  );
                case Routes.dashboard:
                  return MaterialPageRoute(
                    settings: settings,
                    builder: (_) => const DashboardScreen(),
                  );
                case Routes.safetyLoop:
                  return MaterialPageRoute(
                    settings: settings,
                    fullscreenDialog: true,
                    builder: (_) => SafetyLoopScreen(
                      args: (settings.arguments as SafetyLoopArgs?) ??
                          const SafetyLoopArgs.manual(),
                    ),
                  );
                case Routes.stethoscope:
                  return MaterialPageRoute(
                    settings: settings,
                    builder: (_) => const DigitalStethoscopeScreen(),
                  );
                case Routes.bystander:
                  return MaterialPageRoute(
                    settings: settings,
                    fullscreenDialog: true,
                    builder: (_) => BystanderCommandCenterScreen(
                      args: (settings.arguments as BystanderArgs?) ??
                          const BystanderArgs(),
                    ),
                  );
                case Routes.settings:
                  return MaterialPageRoute(
                    settings: settings,
                    builder: (_) => const SettingsPrivacyScreen(),
                  );
                case Routes.sos:
                  return MaterialPageRoute(
                    settings: settings,
                    builder: (_) => const SosScreen(),
                  );
                case Routes.doctorConsult:
                  return MaterialPageRoute(
                    settings: settings,
                    builder: (_) => const DoctorConsultScreen(),
                  );
                case Routes.chatbot:
                  return MaterialPageRoute(
                    settings: settings,
                    builder: (_) => const ChatbotScreen(),
                  );
                case Routes.map:
                  return MaterialPageRoute(
                    settings: settings,
                    builder: (_) => const MapScreen(),
                  );
                case Routes.payment:
                  return MaterialPageRoute(
                    settings: settings,
                    builder: (_) => const PaymentScreen(),
                  );
              }
              return MaterialPageRoute(
                builder: (_) => const Scaffold(
                  body: Center(child: Text('Route not found')),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class AppScope extends InheritedWidget {
  final AppController controller;

  const AppScope({
    required this.controller,
    required super.child,
    super.key,
  });

  static AppController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found');
    return scope!.controller;
  }

  @override
  bool updateShouldNotify(covariant AppScope oldWidget) =>
      oldWidget.controller != controller;
}
