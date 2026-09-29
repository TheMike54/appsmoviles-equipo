import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/theme_provider.dart';
import '../theme/app_theme.dart';

/// Ajustes: elegir el tema Guinda o Azul. El claro/oscuro sigue siempre al
/// sistema, así que no hay control para eso aquí.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Tema', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final choice in AppThemeChoice.values)
              RadioListTile<AppThemeChoice>(
                value: choice,
                groupValue: themeProvider.choice,
                onChanged: (value) {
                  if (value != null) themeProvider.setChoice(value);
                },
                title: Text(choice.label),
                secondary: CircleAvatar(backgroundColor: choice.seedColor),
              ),
            const Divider(height: 32),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Ej4 — Cámara y micrófono'),
              subtitle: const Text(
                'Práctica 3, Desarrollo de Aplicaciones Móviles Nativas '
                '(ESCOM-IPN). Funciona sin conexión a internet.',
              ),
            ),
          ],
        );
      },
    );
  }
}
