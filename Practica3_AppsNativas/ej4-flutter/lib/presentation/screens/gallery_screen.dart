import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models/media_item.dart';
import '../state/gallery_provider.dart';
import 'audio_player_screen.dart';
import 'photo_detail_screen.dart';

/// Galería: fotos en cuadrícula, audios en lista, filtro por álbum con
/// chips y botón para crear álbumes nuevos.
class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  Future<void> _createAlbum(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuevo álbum'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Nombre del álbum'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('Crear'),
          ),
        ],
      ),
    );
    if (name == null || name.trim().isEmpty) return;
    if (!context.mounted) return;
    await context.read<GalleryProvider>().createAlbum(name.trim());
  }

  String _formatDuration(int? durationMs) {
    if (durationMs == null) return '';
    final total = Duration(milliseconds: durationMs);
    final minutes = total.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = total.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GalleryProvider>(
      builder: (context, gallery, _) {
        if (gallery.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final photos = gallery.photos;
        final audios = gallery.audios;
        final isEmpty = photos.isEmpty && audios.isEmpty;

        return Column(
          children: [
            _AlbumChips(
              albums: gallery.albums,
              selected: gallery.selectedAlbum,
              onSelected: gallery.setSelectedAlbum,
              onCreateAlbum: () => _createAlbum(context),
            ),
            Expanded(
              child: isEmpty
                  ? const _EmptyState()
                  : ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        if (photos.isNotEmpty) ...[
                          const _SectionTitle('Fotos'),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: photos.length,
                            itemBuilder: (context, index) {
                              final item = photos[index];
                              return _PhotoThumbnail(item: item);
                            },
                          ),
                          const SizedBox(height: 24),
                        ],
                        if (audios.isNotEmpty) ...[
                          const _SectionTitle('Audios'),
                          for (final item in audios)
                            Card(
                              child: ListTile(
                                leading: const Icon(Icons.audiotrack),
                                title: Text(item.album),
                                subtitle: Text(
                                  '${_formatDuration(item.durationMs)} · '
                                  '${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year}',
                                ),
                                trailing: const Icon(Icons.play_arrow),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          AudioPlayerScreen(item: item),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.collections_outlined, size: 72),
            const SizedBox(height: 16),
            Text(
              'Todavía no hay fotos ni audios en este álbum.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _AlbumChips extends StatelessWidget {
  const _AlbumChips({
    required this.albums,
    required this.selected,
    required this.onSelected,
    required this.onCreateAlbum,
  });

  final List<String> albums;
  final String selected;
  final ValueChanged<String> onSelected;
  final VoidCallback onCreateAlbum;

  @override
  Widget build(BuildContext context) {
    final options = [kAllAlbumsFilter, ...albums];
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          for (final album in options)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(album),
                selected: album == selected,
                onSelected: (_) => onSelected(album),
              ),
            ),
          ActionChip(
            avatar: const Icon(Icons.add, size: 18),
            label: const Text('Álbum'),
            onPressed: onCreateAlbum,
          ),
        ],
      ),
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  const _PhotoThumbnail({required this.item});
  final MediaItem item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PhotoDetailScreen(item: item)),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(item.filePath),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
