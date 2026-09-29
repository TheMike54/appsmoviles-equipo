import 'package:flutter/foundation.dart';

import '../../domain/repositories/settings_repository.dart';
import '../theme/app_theme.dart';

/// Estado global del tema elegido (Guinda/Azul). El claro/oscuro NO se
/// controla aquí: sigue siempre al sistema (ThemeMode.system en MaterialApp).
class ThemeProvider extends ChangeNotifier {
  static const _key = 'theme_choice';

  final SettingsRepository _settingsRepository;
  AppThemeChoice _choice = AppThemeChoice.guinda;

  ThemeProvider(this._settingsRepository) {
    _load();
  }

  AppThemeChoice get choice => _choice;

  Future<void> _load() async {
    final value = await _settingsRepository.getValue(_key);
    _choice = AppThemeChoiceX.fromDbValue(value);
    notifyListeners();
  }

  Future<void> setChoice(AppThemeChoice choice) async {
    if (choice == _choice) return;
    _choice = choice;
    notifyListeners();
    await _settingsRepository.setValue(_key, choice.toDbValue());
  }
}
