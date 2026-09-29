/// Contrato para leer/guardar preferencias simples (por ejemplo, el tema
/// elegido). Se implementa en la capa data usando la misma base de sqflite,
/// para no depender de un paquete adicional no probado en la Mac.
abstract class SettingsRepository {
  Future<String?> getValue(String key);
  Future<void> setValue(String key, String value);
}
