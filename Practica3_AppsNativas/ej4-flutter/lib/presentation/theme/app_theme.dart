import 'package:flutter/material.dart';

/// Tonos exactos acordados por el equipo (COLORES.md) para que Guinda y Azul
/// se vean igual en las 4 apps de la práctica.
class AppColors {
  static const guinda = Color(0xFF6C1D45); // IPN
  static const azul = Color(0xFF0D2F5A); // ESCOM
}

enum AppThemeChoice { guinda, azul }

extension AppThemeChoiceX on AppThemeChoice {
  Color get seedColor =>
      this == AppThemeChoice.guinda ? AppColors.guinda : AppColors.azul;

  String get label =>
      this == AppThemeChoice.guinda ? 'Guinda (IPN)' : 'Azul (ESCOM)';

  String toDbValue() => this == AppThemeChoice.guinda ? 'guinda' : 'azul';

  static AppThemeChoice fromDbValue(String? value) {
    return value == 'azul' ? AppThemeChoice.azul : AppThemeChoice.guinda;
  }
}

/// Genera los ThemeData claro/oscuro a partir del color semilla elegido.
/// En modo oscuro Flutter aclara automáticamente el color principal
/// (ColorScheme.fromSeed con brightness: dark) para que tenga contraste.
class AppTheme {
  static ThemeData light(AppThemeChoice choice) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: choice.seedColor,
        brightness: Brightness.light,
      ),
    );
  }

  static ThemeData dark(AppThemeChoice choice) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: choice.seedColor,
        brightness: Brightness.dark,
      ),
    );
  }
}
