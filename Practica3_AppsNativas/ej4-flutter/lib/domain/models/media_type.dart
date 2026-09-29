/// Tipo de medio guardado por la app: foto o audio.
enum MediaType { photo, audio }

extension MediaTypeStorage on MediaType {
  String toDbValue() => this == MediaType.photo ? 'photo' : 'audio';

  static MediaType fromDbValue(String value) {
    return value == 'photo' ? MediaType.photo : MediaType.audio;
  }
}
