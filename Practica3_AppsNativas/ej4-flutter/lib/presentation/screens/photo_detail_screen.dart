import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/models/media_item.dart';
import '../state/gallery_provider.dart';
import '../utils/photo_filters.dart';

/// Detalle de una foto: edición básica (rotar, cambiar filtro), compartir y
/// borrar. Cada edición genera un archivo nuevo y actualiza el registro en
/// sqflite (así la miniatura de la galería no queda con una imagen en caché).
class PhotoDetailScreen extends StatefulWidget {
  const PhotoDetailScreen({super.key, required this.item});

  final MediaItem item;

  @override
  State<PhotoDetailScreen> createState() => _PhotoDetailScreenState();
}

class _PhotoDetailScreenState extends State<PhotoDetailScreen> {
  late MediaItem _item;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
  }

  Future<File> _newFileNextToOriginal() async {
    final original = File(_item.filePath);
    final ext = p.extension(original.path);
    final tempDir = await getTemporaryDirectory();
    return File(
      p.join(tempDir.path, 'edit_${DateTime.now().millisecondsSinceEpoch}$ext'),
    );
  }

  Future<void> _applyEdit(
    Future<File> Function(File source, File destination) editFn, {
    String? newFilterValue,
  }) async {
    setState(() => _working = true);
    final oldFile = File(_item.filePath);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final workingCopy = await _newFileNextToOriginal();
      await editFn(oldFile, workingCopy);

      final permanentDir = oldFile.parent;
      final permanentPath = p.join(
        permanentDir.path,
        p.basename(workingCopy.path),
      );
      await workingCopy.copy(permanentPath);
      if (await workingCopy.exists()) await workingCopy.delete();

      final updated = _item.copyWith(
        filePath: permanentPath,
        filter: newFilterValue ?? _item.filter,
      );
      await context.read<GalleryProvider>().updateItem(updated);

      if (await oldFile.exists()) await oldFile.delete();

      if (!mounted) return;
      setState(() {
        _item = updated;
        _working = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _working = false);
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('No se pudo editar la foto: $e')),
      );
    }
  }

  Future<void> _rotate() async {
    await _applyEdit(
      (source, destination) =>
          rotatePhotoFile(source: source, destination: destination),
    );
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
                onTap: () => Navigator.of(ctx).pop(filter),
              ),
          ],
        ),
      ),
    );
    if (selected == null) return;
    await _applyEdit(
      (source, destination) => applyPhotoFilter(
        source: source,
        filter: selected,
        destination: destination,
      ),
      newFilterValue: selected.toDbValue(),
    );
  }

  Future<void> _share() async {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(_item.filePath)], text: 'Foto de Ej4 Flutter'),
    );
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Borrar foto'),
        content: const Text('¿Seguro que quieres borrar esta foto?'),
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
    await context.read<GalleryProvider>().deleteItem(_item);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_item.album),
        actions: [
          IconButton(onPressed: _share, icon: const Icon(Icons.share)),
          IconButton(onPressed: _delete, icon: const Icon(Icons.delete_outline)),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _working
                  ? const CircularProgressIndicator()
                  : InteractiveViewer(
                      child: Image.file(File(_item.filePath)),
                    ),
            ),
          ),
          SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: _working ? null : _rotate,
                  icon: const Icon(Icons.rotate_right),
                  label: const Text('Rotar'),
                ),
                TextButton.icon(
                  onPressed: _working ? null : _pickFilter,
                  icon: const Icon(Icons.filter_vintage_outlined),
                  label: const Text('Filtro'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
