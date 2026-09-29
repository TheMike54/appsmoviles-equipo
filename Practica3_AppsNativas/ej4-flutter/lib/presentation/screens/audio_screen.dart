import 'dart:async';
import 'dart:io';
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';

import '../../domain/constants.dart';
import '../../domain/models/media_type.dart';
import '../state/gallery_provider.dart';
import '../utils/audio_sensitivity.dart';
import '../widgets/mensaje_estado.dart';

const List<int> kMaxDurationOptions = [15, 30, 60, 120];

/// Pantalla de grabadora: sensibilidad y temporizador de grabación.
/// El permiso de micrófono lo pide el propio plugin `record` con
/// hasPermission(); si se niega, o si el dispositivo no tiene micrófono
/// (como el simulador de iPhone), la pantalla lo explica en vez de trabarse.
class AudioScreen extends StatefulWidget {
  const AudioScreen({super.key});

  @override
  State<AudioScreen> createState() => _AudioScreenState();
}

class _AudioScreenState extends State<AudioScreen> {
  final _recorder = AudioRecorder();

  bool _checkingPermission = true;
  bool _permissionGranted = false;

  bool _isRecording = false;
  int _elapsedSeconds = 0;
  Timer? _ticker;

  AudioSensitivity _sensitivity = AudioSensitivity.media;
  int _maxDurationSeconds = 30;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    setState(() => _checkingPermission = true);
    var granted = false;
    try {
      // hasPermission() solicita el permiso de micrófono si aún no se ha dado.
      granted = await _recorder.hasPermission();
    } catch (_) {
      granted = false;
    }
    if (!mounted) return;
    setState(() {
      _permissionGranted = granted;
      _checkingPermission = false;
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final path =
          '${tempDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final config = RecordConfig(
        encoder: AudioEncoder.aacLc,
        autoGain: _sensitivity.autoGain,
        noiseSuppress: _sensitivity.noiseSuppress,
        echoCancel: _sensitivity.echoCancel,
      );
      await _recorder.start(config, path: path);

      if (!mounted) return;
      setState(() {
        _isRecording = true;
        _elapsedSeconds = 0;
      });

      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _elapsedSeconds++);
        if (_elapsedSeconds >= _maxDurationSeconds) {
          _stopRecording();
        }
      });
    } catch (_) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Sin micrófono'),
          content: const Text(
            'Este dispositivo no tiene un micrófono disponible para grabar '
            '(por ejemplo, el simulador de iPhone). Prueba en un dispositivo '
            'o emulador con micrófono.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _stopRecording() async {
    _ticker?.cancel();
    _ticker = null;
    String? path;
    try {
      path = await _recorder.stop();
    } catch (_) {
      path = null;
    }

    final elapsedMs = _elapsedSeconds * 1000;
    if (mounted) setState(() => _isRecording = false);

    if (path == null) return;
    if (!mounted) return;

    await context.read<GalleryProvider>().addMedia(
          sourceFile: File(path),
          type: MediaType.audio,
          album: kDefaultAlbum,
          durationMs: elapsedMs,
        );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Audio guardado en la galería.')),
    );
  }

  String _formatElapsed() {
    final minutes = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingPermission) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_permissionGranted) {
      return MensajeEstado(
        icono: Icons.mic_off_outlined,
        mensaje:
            'No se concedió el permiso de micrófono, así que no se puede '
            'grabar audio. Puedes activarlo en los ajustes del sistema y '
            'volver a intentar.',
        acciones: [
          FilledButton(
            onPressed: _checkPermission,
            child: const Text('Volver a intentar'),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Text(
            _formatElapsed(),
            style: Theme.of(context)
                .textTheme
                .displayMedium
                ?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
          Text('máximo ${_maxDurationSeconds}s'),
          const SizedBox(height: 32),
          DropdownButtonFormField<AudioSensitivity>(
            value: _sensitivity,
            decoration: const InputDecoration(labelText: 'Sensibilidad'),
            items: [
              for (final s in AudioSensitivity.values)
                DropdownMenuItem(value: s, child: Text(s.label)),
            ],
            onChanged: _isRecording
                ? null
                : (value) {
                    if (value != null) setState(() => _sensitivity = value);
                  },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            value: _maxDurationSeconds,
            decoration:
                const InputDecoration(labelText: 'Temporizador de grabación'),
            items: [
              for (final seconds in kMaxDurationOptions)
                DropdownMenuItem(value: seconds, child: Text('${seconds}s')),
            ],
            onChanged: _isRecording
                ? null
                : (value) {
                    if (value != null) {
                      setState(() => _maxDurationSeconds = value);
                    }
                  },
          ),
          const Spacer(),
          FloatingActionButton.large(
            onPressed: _toggleRecording,
            backgroundColor:
                _isRecording ? Theme.of(context).colorScheme.error : null,
            child: Icon(_isRecording ? Icons.stop : Icons.mic),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
