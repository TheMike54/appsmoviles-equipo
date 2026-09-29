import 'package:flutter/material.dart';

import 'audio_screen.dart';
import 'camera_screen.dart';
import 'gallery_screen.dart';
import 'settings_screen.dart';

/// Cascarón de navegación: misma barra inferior, mismo orden de pestañas y
/// mismos textos en Android e iOS (requisito 4.3 de consistencia).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  static const _titles = ['Cámara', 'Audio', 'Galería', 'Ajustes'];

  Widget _buildBody() {
    // Se construye una instancia nueva cada vez: así la pantalla de cámara
    // libera el controlador de la cámara al salir de su pestaña, en vez de
    // mantenerla abierta de fondo en las otras pestañas.
    switch (_index) {
      case 0:
        return const CameraScreen();
      case 1:
        return const AudioScreen();
      case 2:
        return const GalleryScreen();
      default:
        return const SettingsScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index])),
      body: _buildBody(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.camera_alt_outlined),
            selectedIcon: Icon(Icons.camera_alt),
            label: 'Cámara',
          ),
          NavigationDestination(
            icon: Icon(Icons.mic_none_outlined),
            selectedIcon: Icon(Icons.mic),
            label: 'Audio',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_library_outlined),
            selectedIcon: Icon(Icons.photo_library),
            label: 'Galería',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}
