import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../domain/models/media_item.dart';
import '../../domain/models/media_type.dart';
import '../../domain/repositories/media_repository.dart';

const String kAllAlbumsFilter = 'Todos';

/// Estado de la galería: lista de medios, álbumes disponibles y el álbum
/// seleccionado para filtrar. Las pantallas (cámara, audio, galería) llaman
/// a este provider en vez de hablar directo con el repositorio.
class GalleryProvider extends ChangeNotifier {
  final MediaRepository _repository;

  List<MediaItem> _allItems = [];
  List<String> _albums = [];
  String _selectedAlbum = kAllAlbumsFilter;
  bool _loading = true;

  GalleryProvider(this._repository) {
    refresh();
  }

  bool get isLoading => _loading;

  List<String> get albums => _albums;

  String get selectedAlbum => _selectedAlbum;

  List<MediaItem> get items {
    if (_selectedAlbum == kAllAlbumsFilter) return _allItems;
    return _allItems.where((item) => item.album == _selectedAlbum).toList();
  }

  List<MediaItem> get photos =>
      items.where((item) => item.type == MediaType.photo).toList();

  List<MediaItem> get audios =>
      items.where((item) => item.type == MediaType.audio).toList();

  Future<void> refresh() async {
    _allItems = await _repository.getAll();
    _albums = await _repository.getAlbums();
    _loading = false;
    notifyListeners();
  }

  void setSelectedAlbum(String album) {
    _selectedAlbum = album;
    notifyListeners();
  }

  Future<MediaItem> addMedia({
    required File sourceFile,
    required MediaType type,
    required String album,
    String? filter,
    int? durationMs,
  }) async {
    final item = await _repository.saveNewMedia(
      sourceFile: sourceFile,
      type: type,
      album: album,
      filter: filter,
      durationMs: durationMs,
    );
    await refresh();
    return item;
  }

  Future<void> updateItem(MediaItem item) async {
    await _repository.update(item);
    await refresh();
  }

  Future<void> deleteItem(MediaItem item) async {
    await _repository.delete(item);
    await refresh();
  }

  Future<void> createAlbum(String name) async {
    await _repository.createAlbum(name);
    await refresh();
  }
}
