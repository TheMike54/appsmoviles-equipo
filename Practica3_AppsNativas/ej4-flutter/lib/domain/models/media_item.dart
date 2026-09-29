import 'media_type.dart';

/// Entidad de dominio: una foto o un audio guardado por la app, con sus
/// metadatos. No sabe nada de sqflite ni de archivos: eso vive en la capa data.
class MediaItem {
  final int? id;
  final MediaType type;
  final String filePath;
  final String album;
  final DateTime createdAt;

  /// Filtro aplicado a la foto (ver `PhotoFilter` en la capa de presentación).
  /// Nulo para audios.
  final String? filter;

  /// Duración en milisegundos, solo para audios.
  final int? durationMs;

  const MediaItem({
    this.id,
    required this.type,
    required this.filePath,
    required this.album,
    required this.createdAt,
    this.filter,
    this.durationMs,
  });

  MediaItem copyWith({
    int? id,
    MediaType? type,
    String? filePath,
    String? album,
    DateTime? createdAt,
    String? filter,
    int? durationMs,
  }) {
    return MediaItem(
      id: id ?? this.id,
      type: type ?? this.type,
      filePath: filePath ?? this.filePath,
      album: album ?? this.album,
      createdAt: createdAt ?? this.createdAt,
      filter: filter ?? this.filter,
      durationMs: durationMs ?? this.durationMs,
    );
  }
}
