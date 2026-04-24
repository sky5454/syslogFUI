import 'package:flutter/material.dart';

class AppTheme {
  static const Color backgroundColor = Color(0xFF1E1E1E);
  static const Color surfaceColor = Color(0xFF252526);
  static const Color cardColor = Color(0xFF2D2D30);
  static const Color primaryColor = Color(0xFF007ACC);
  static const Color accentColor = Color(0xFF3794FF);

  static const Color emergencyColor = Color(0xFFFF5252);
  static const Color alertColor = Color(0xFFFF5252);
  static const Color criticalColor = Color(0xFFFF5252);
  static const Color errorColor = Color(0xFFFF9800);
  static const Color warningColor = Color(0xFFFFEB3B);
  static const Color noticeColor = Color(0xFF2196F3);
  static const Color infoColor = Color(0xFF9E9E9E);
  static const Color debugColor = Color(0xFF4CAF50);

  static Color getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'emergency': return emergencyColor;
      case 'alert': return alertColor;
      case 'critical': return criticalColor;
      case 'error': return errorColor;
      case 'warning': return warningColor;
      case 'notice': return noticeColor;
      case 'info': return infoColor;
      case 'debug': return debugColor;
      default: return infoColor;
    }
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundColor,
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: accentColor,
        surface: surfaceColor,
      ),
      cardTheme: const CardThemeData(
        color: cardColor,
        elevation: 0,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceColor,
        elevation: 0,
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(surfaceColor),
        dataRowColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return cardColor.withOpacity(0.8);
          }
          return Colors.transparent;
        }),
      ),
      dividerColor: Colors.white12,
      iconTheme: const IconThemeData(color: Colors.white70),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white70),
        bodySmall: TextStyle(color: Colors.white54),
      ),
    );
  }
}
