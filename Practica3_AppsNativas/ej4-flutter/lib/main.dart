import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/repositories/media_repository_impl.dart';
import 'data/repositories/settings_repository_impl.dart';
import 'domain/repositories/media_repository.dart';
import 'domain/repositories/settings_repository.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/state/gallery_provider.dart';
import 'presentation/state/theme_provider.dart';
import 'presentation/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const Ej4App());
}

/// Punto de entrada: arma las implementaciones concretas de la capa data
/// y las expone a toda la app a través de Provider. Las pantallas solo
/// dependen de las interfaces de domain (MediaRepository, SettingsRepository).
class Ej4App extends StatelessWidget {
  const Ej4App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<MediaRepository>(create: (_) => MediaRepositoryImpl()),
        Provider<SettingsRepository>(create: (_) => SettingsRepositoryImpl()),
        ChangeNotifierProxyProvider<SettingsRepository, ThemeProvider>(
          create: (context) =>
              ThemeProvider(context.read<SettingsRepository>()),
          update: (context, settingsRepository, previous) =>
              previous ?? ThemeProvider(settingsRepository),
        ),
        ChangeNotifierProxyProvider<MediaRepository, GalleryProvider>(
          create: (context) => GalleryProvider(context.read<MediaRepository>()),
          update: (context, mediaRepository, previous) =>
              previous ?? GalleryProvider(mediaRepository),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Ej4 Cámara y Micrófono',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(themeProvider.choice),
            darkTheme: AppTheme.dark(themeProvider.choice),
            themeMode: ThemeMode.system,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
