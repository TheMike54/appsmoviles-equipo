import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/models/media_item.dart';
import '../state/gallery_provider.dart';

/// Reproductor de un audio guardado: play/pause, barra de progreso,
/// compartir y borrar.
class AudioPlayerScreen extends StatefulWidget {
  const AudioPlayerScreen({super.key, required this.item});

  final MediaItem item;

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  final _player = AudioPlayer();
  bool _ready = false;
  bool _loadError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await _player.setFilePath(widget.item.filePath);
      if (!mounted) return;
      setState(() => _ready = true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadError = true);
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _format(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _share() async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(widget.item.filePath)],
        text: 'Audio de Ej4 Flutter',
      ),
    );
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Borrar audio'),
        content: const Text('¿Seguro que quieres borrar este audio?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;
    await context.read<GalleryProvider>().deleteItem(widget.item);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item.album),
        actions: [
          IconButton(onPressed: _share, icon: const Icon(Icons.share)),
          IconButton(onPressed: _delete, icon: const Icon(Icons.delete_outline)),
        ],
      ),
      body: Center(
        child: _loadError
            ? const Text('No se pudo abrir este audio.')
            : !_ready
                ? const CircularProgressIndicator()
                : Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.audiotrack, size: 72),
                        const SizedBox(height: 24),
                        StreamBuilder<Duration?>(
                          stream: _player.durationStream,
                          builder: (context, durationSnapshot) {
                            final duration =
                                durationSnapshot.data ?? Duration.zero;
                            return StreamBuilder<Duration>(
                              stream: _player.positionStream,
                              builder: (context, positionSnapshot) {
                                final position =
                                    positionSnapshot.data ?? Duration.zero;
                                final clampedPosition =
                                    position > duration ? duration : position;
                                return Column(
                                  children: [
                                    Slider(
                                      max: duration.inMilliseconds.toDouble().clamp(
                                          1, double.infinity),
                                      value: clampedPosition.inMilliseconds
                                          .toDouble()
                                          .clamp(0, duration.inMilliseconds.toDouble().clamp(1, double.infinity)),
                                      onChanged: (value) {
                                        _player.seek(
                                          Duration(milliseconds: value.round()),
                                        );
                                      },
                                    ),
                                    Text(
                                      '${_format(clampedPosition)} / ${_format(duration)}',
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        StreamBuilder<PlayerState>(
                          stream: _player.playerStateStream,
                          builder: (context, snapshot) {
                            final playing = snapshot.data?.playing ?? false;
                            return FloatingActionButton(
                              onPressed: () {
                                if (playing) {
                                  _player.pause();
                                } else {
                                  if (_player.position >= (_player.duration ??
                                      Duration.zero)) {
                                    _player.seek(Duration.zero);
                                  }
                                  _player.play();
                                }
                              },
                              child: Icon(playing ? Icons.pause : Icons.play_arrow),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
