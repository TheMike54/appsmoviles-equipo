import 'dart:io';
import 'dart:ui' as ui;

/// Filtros de foto. Se aplican con dart:ui (sin paquetes extra) tanto en la
/// vista previa (ColorFiltered) como al guardar la foto final, para que se
/// vea igual en la preview y en la galería.
enum PhotoFilter { normal, blancoYNegro, sepia }

extension PhotoFilterX on PhotoFilter {
  String get label {
    switch (this) {
      case PhotoFilter.normal:
        return 'Normal';
      case PhotoFilter.blancoYNegro:
        return 'Blanco y negro';
      case PhotoFilter.sepia:
        return 'Sepia';
    }
  }

  String toDbValue() => name;

  static PhotoFilter fromDbValue(String? value) {
    return PhotoFilter.values.firstWhere(
      (f) => f.name == value,
      orElse: () => PhotoFilter.normal,
    );
  }

  /// Matriz 4x5 de ColorFilter.matrix; null significa "sin filtro".
  List<double>? get matrix {
    switch (this) {
      case PhotoFilter.normal:
        return null;
      case PhotoFilter.blancoYNegro:
        return const [
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 1, 0,
        ];
      case PhotoFilter.sepia:
        return const [
          0.393, 0.769, 0.189, 0, 0,
          0.349, 0.686, 0.168, 0, 0,
          0.272, 0.534, 0.131, 0, 0,
          0, 0, 0, 1, 0,
        ];
    }
  }
}

/// Decodifica [source], le aplica [filter] (o solo copia si es "normal") y
/// escribe el resultado en [destination]. Regresa [destination].
Future<File> applyPhotoFilter({
  required File source,
  required PhotoFilter filter,
  required File destination,
}) async {
  final matrix = filter.matrix;
  if (matrix == null) {
    await source.copy(destination.path);
    return destination;
  }

  final bytes = await source.readAsBytes();
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  final image = frame.image;

  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  final paint = ui.Paint()..colorFilter = ui.ColorFilter.matrix(matrix);
  canvas.drawImage(image, ui.Offset.zero, paint);
  final picture = recorder.endRecording();
  final outputImage = await picture.toImage(image.width, image.height);
  final byteData =
      await outputImage.toByteData(format: ui.ImageByteFormat.png);

  if (byteData == null) {
    await source.copy(destination.path);
    return destination;
  }

  await destination.writeAsBytes(byteData.buffer.asUint8List());
  return destination;
}


/// Rota [source] 90 grados en sentido de las manecillas y escribe el
/// resultado en [destination] (edición básica que pide el checklist).
Future<File> rotatePhotoFile({
  required File source,
  required File destination,
}) async {
  final bytes = await source.readAsBytes();
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  final image = frame.image;

  final originalWidth = image.width.toDouble();
  final originalHeight = image.height.toDouble();

  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.translate(originalHeight / 2, originalWidth / 2);
  canvas.rotate(1.5707963267948966); // 90 grados en radianes (pi/2)
  canvas.translate(-originalWidth / 2, -originalHeight / 2);
  canvas.drawImage(image, ui.Offset.zero, ui.Paint());

  final picture = recorder.endRecording();
  final rotatedImage =
      await picture.toImage(image.height, image.width);
  final byteData =
      await rotatedImage.toByteData(format: ui.ImageByteFormat.png);

  if (byteData == null) {
    await source.copy(destination.path);
    return destination;
  }

  await destination.writeAsBytes(byteData.buffer.asUint8List());
  return destination;
}
