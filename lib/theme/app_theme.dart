import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFB71C1C),
      brightness: Brightness.light,
    );

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF7F7FB),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      // Prevent RawTooltipState multiple-ticker crash on Flutter web.
      // By using manual trigger mode, the tooltip animation controller
      // is only created when explicitly shown, avoiding the
      // SingleTickerProviderStateMixin conflict.
      tooltipTheme: const TooltipThemeData(
        triggerMode: TooltipTriggerMode.manual,
      ),
    );
  }
}
