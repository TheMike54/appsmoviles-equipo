import 'dart:io';

import '../models/media_item.dart';
import '../models/media_type.dart';

/// Contrato de la capa domain hacia la persistencia. La capa presentation
/// solo conoce esta interfaz; quien la implementa (capa data) decide cómo
/// se guarda de verdad (sqflite + sistema de archivos).
abstract class MediaRepository {
  Future<List<MediaItem>> getAll();

  Future<List<String>> getAlbums();

  /// Copia [sourceFile] al almacenamiento propio de la app y guarda sus
  /// metadatos. Regresa el MediaItem ya con su id asignado.
  Future<MediaItem> saveNewMedia({
    required File sourceFile,
    required MediaType type,
    required String album,
    String? filter,
    int? durationMs,
  });

  Future<void> update(MediaItem item);

  Future<void> delete(MediaItem item);

  Future<void> createAlbum(String name);
}
