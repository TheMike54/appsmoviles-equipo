import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../domain/constants.dart';
import '../../domain/models/media_type.dart';
import '../state/gallery_provider.dart';
import '../utils/photo_filters.dart';
import '../widgets/mensaje_estado.dart';

const List<int> kTimerOptions = [0, 3, 5, 10];

/// Pantalla de cámara: preview en vivo con flash, temporizador y filtro.
/// El permiso de cámara lo pide el propio plugin `camera` al inicializar; si
/// el usuario lo niega o el equipo no tiene cámara (como el simulador de
/// iPhone), la pantalla lo explica y ofrece elegir una foto de la galería.
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _initializing = true;
  bool _cameraAvailable = false;
  bool _permisoNegado = false;
  String _unavailableMessage = 'No hay cámara disponible en este dispositivo.';

  FlashMode _flashMode = FlashMode.off;
  int _timerSeconds = 0;
  PhotoFilter _filter = PhotoFilter.normal;

  int? _countdown;
  bool _capturing = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() {
      _initializing = true;
      _permisoNegado = false;
    });

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraException('sin_camara', 'No hay cámaras disponibles');
      }
      final controller = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      // initialize() es quien dispara la solicitud de permiso de cámara en
      // Android e iOS; si el usuario la niega, lanza CameraException.
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _cameraAvailable = true;
        _initializing = false;
      });
    } on CameraException catch (e) {
      if (!mounted) return;
      final negado = e.code == 'CameraAccessDenied' ||
          e.code == 'CameraAccessDeniedWithoutPrompt' ||
          e.code == 'CameraAccessRestricted';
      setState(() {
        _cameraAvailable = false;
        _permisoNegado = negado;
        _unavailableMessage = negado
            ? 'No se concedió el permiso de cámara, así que no se puede '
                'tomar fotos. Puedes activarlo en los ajustes del sistema, o '
                'elegir una foto de tu galería.'
            : 'Este equipo no tiene una cámara utilizable (por ejemplo, el '
                'simulador de iPhone). Elige una foto de tu galería en su '
                'lugar.';
        _initializing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cameraAvailable = false;
        _unavailableMessage =
            'No se pudo abrir la cámara en este equipo. Elige una foto de tu '
            'galería en su lugar.';
        _initializing = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _toggleFlash() async {
    final controller = _controller;
    if (controller == null) return;
    final next = switch (_flashMode) {
      FlashMode.off => FlashMode.auto,
      FlashMode.auto => FlashMode.torch,
      FlashMode.torch => FlashMode.off,
      FlashMode.always => FlashMode.off,
    };
    try {
      await controller.setFlashMode(next);
      setState(() => _flashMode = next);
    } catch (_) {
      // Algunos emuladores no soportan flash; se ignora sin tronar.
    }
  }

  IconData get _flashIcon {
    switch (_flashMode) {
      case FlashMode.off:
        return Icons.flash_off;
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.torch:
        return Icons.flash_on;
      case FlashMode.always:
        return Icons.flash_on;
    }
  }

  Future<void> _onCapturePressed() async {
    if (_capturing) return;
    if (_timerSeconds > 0) {
      for (var remaining = _timerSeconds; remaining > 0; remaining--) {
        if (!mounted) return;
        setState(() => _countdown = remaining);
        await Future<void>.delayed(const Duration(seconds: 1));
      }
      if (!mounted) return;
      setState(() => _countdown = null);
    }
    await _takePhoto();
  }

  Future<void> _takePhoto() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    setState(() => _capturing = true);
    try {
      final captured = await controller.takePicture();
      await _saveCapturedFile(File(captured.path));
    } catch (e) {
      _showMessage('No se pudo tomar la foto: $e');
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final picked =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked == null) return;
      await _saveCapturedFile(File(picked.path));
    } catch (e) {
      _showMessage('No se pudo abrir la galería: $e');
    }
  }

  Future<void> _saveCapturedFile(File rawFile) async {
    final tempDir = await getTemporaryDirectory();
    final filteredPath =
        '${tempDir.path}/filtro_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final filteredFile = File(filteredPath);

    await applyPhotoFilter(
      source: rawFile,
      filter: _filter,
      destination: filteredFile,
    );

    if (!mounted) return;
    await context.read<GalleryProvider>().addMedia(
          sourceFile: filteredFile,
          type: MediaType.photo,
          album: kDefaultAlbum,
          filter: _filter.toDbValue(),
        );

    if (await filteredFile.exists()) {
      await filteredFile.delete();
    }

    _showMessage('Foto guardada en la galería.');
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickTimer() async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final seconds in kTimerOptions)
              ListTile(
                title: Text(seconds == 0 ? 'Sin temporizador' : '$seconds s'),
                trailing:
                    seconds == _timerSeconds ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(ctx).pop(seconds),
              ),
          ],
        ),
      ),
    );
    if (selected != null) setState(() => _timerSeconds = selected);
  }

  Future<void> _pickFilter() async {
    final selected = await showModalBottomSheet<PhotoFilter>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final filter in PhotoFilter.values)
              ListTile(
                title: Text(filter.label),
                trailing: filter == _filter ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(ctx).pop(filter),
              ),
          ],
        ),
      ),
    );
    if (selected != null) setState(() => _filter = selected);
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_cameraAvailable || _controller == null) {
      return MensajeEstado(
        icono: _permisoNegado
            ? Icons.no_photography_outlined
            : Icons.videocam_off_outlined,
        mensaje: _unavailableMessage,
        acciones: [
          FilledButton.icon(
            onPressed: _pickFromGallery,
            icon: const Icon(Icons.photo_library),
            label: const Text('Elegir foto de la galería'),
          ),
          OutlinedButton(
            onPressed: _init,
            child: const Text('Volver a intentar'),
          ),
        ],
      );
    }

    return Column(
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              _filter.matrix == null
                  ? CameraPreview(_controller!)
                  : ColorFiltered(
                      colorFilter: ColorFilter.matrix(_filter.matrix!),
                      child: CameraPreview(_controller!),
                    ),
              if (_countdown != null)
                Center(
                  child: Text(
                    '$_countdown',
                    style: const TextStyle(
                      fontSize: 96,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(blurRadius: 12, color: Colors.black)],
                    ),
                  ),
                ),
            ],
          ),
        ),
        _buildControls(),
      ],
    );
  }

  Widget _buildControls() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: _toggleFlash,
                  icon: Icon(_flashIcon),
                  tooltip: 'Flash',
                ),
                TextButton.icon(
                  onPressed: _pickTimer,
                  icon: const Icon(Icons.timer_outlined),
                  label: Text(
                    _timerSeconds == 0 ? 'Sin timer' : '${_timerSeconds}s',
                  ),
                ),
                TextButton.icon(
                  onPressed: _pickFilter,
                  icon: const Icon(Icons.filter_vintage_outlined),
                  label: Text(_filter.label),
                ),
                IconButton(
                  onPressed: _pickFromGallery,
                  icon: const Icon(Icons.photo_library_outlined),
                  tooltip: 'Elegir de la galería',
                ),
              ],
            ),
            const SizedBox(height: 8),
            FloatingActionButton(
              onPressed: _capturing ? null : _onCapturePressed,
              child: _capturing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.camera_alt),
            ),
          ],
        ),
      ),
    );
  }
}
