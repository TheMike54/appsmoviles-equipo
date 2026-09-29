/// Niveles de sensibilidad del micrófono que pide el checklist. Se traducen
/// a las opciones que sí existe en el plugin `record` (auto-gain, supresión
/// de ruido y cancelación de eco), documentado en la sección del informe.
enum AudioSensitivity { baja, media, alta }

extension AudioSensitivityX on AudioSensitivity {
  String get label {
    switch (this) {
      case AudioSensitivity.baja:
        return 'Baja (filtra más ruido)';
      case AudioSensitivity.media:
        return 'Media';
      case AudioSensitivity.alta:
        return 'Alta (capta más sonido)';
    }
  }

  bool get autoGain => this != AudioSensitivity.baja;

  bool get noiseSuppress => this != AudioSensitivity.alta;

  bool get echoCancel => this == AudioSensitivity.baja;
}
