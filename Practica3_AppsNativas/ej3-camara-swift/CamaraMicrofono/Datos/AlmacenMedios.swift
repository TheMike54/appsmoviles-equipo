import UIKit
import CoreData
import AVFoundation
import ImageIO
import CryptoKit

/// Guarda los archivos capturados en el almacenamiento del dispositivo y sus metadatos en Core Data.
///
/// - Fotos: `Documents/Fotos/*.jpg` · Grabaciones: `Documents/Audios/*.m4a` / `*.wav`
/// - Miniaturas: caché en memoria + `Library/Caches/Miniaturas` para abrir la galería rápido.
enum AlmacenMedios {
    static let carpetaDocumentos = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    static let carpetaFotos = carpetaDocumentos.appendingPathComponent("Fotos", isDirectory: true)
    static let carpetaAudios = carpetaDocumentos.appendingPathComponent("Audios", isDirectory: true)
    private static let carpetaMiniaturas = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("Miniaturas", isDirectory: true)
    private static let cache = NSCache<NSString, UIImage>()

    static func prepararCarpetas() {
        for carpeta in [carpetaFotos, carpetaAudios, carpetaMiniaturas] {
            try? FileManager.default.createDirectory(at: carpeta, withIntermediateDirectories: true)
        }
    }

    private static var contexto: NSManagedObjectContext { Persistencia.compartida.contexto }

    // MARK: Guardar

    /// Guarda una foto (JPEG) y crea su registro en Core Data.
    @discardableResult
    static func guardarFoto(_ imagen: UIImage, filtro: Filtro, ubicacion: (Double, Double)?, album: Album? = nil) throws -> Medio {
        prepararCarpetas()
        guard let datos = imagen.jpegData(compressionQuality: 0.9) else { throw ErrorMedio.noSePudoGuardar }
        let nombre = "Foto_\(marcaDeTiempo()).jpg"
        try datos.write(to: carpetaFotos.appendingPathComponent(nombre))
        return crearMedio(tipo: "foto", archivo: "Fotos/\(nombre)", filtro: filtro == .original ? nil : filtro.rawValue,
                          ubicacion: ubicacion, album: album)
    }

    /// Registra una grabación que ya se escribió en `Documents/Audios`.
    @discardableResult
    static func registrarAudio(nombre: String, duracion: Double, ubicacion: (Double, Double)?) -> Medio {
        let medio = crearMedio(tipo: "audio", archivo: "Audios/\(nombre)", filtro: nil, ubicacion: ubicacion, album: nil)
        medio.duracion = duracion
        Persistencia.compartida.guardar()
        return medio
    }

    static func nuevaURLDeAudio() -> URL {
        prepararCarpetas()
        return carpetaAudios.appendingPathComponent("Grabacion_\(marcaDeTiempo()).m4a")
    }

    private static func crearMedio(tipo: String, archivo: String, filtro: String?, ubicacion: (Double, Double)?, album: Album?) -> Medio {
        let medio = Medio(context: contexto)
        medio.id = UUID()
        medio.tipo = tipo
        medio.archivo = archivo
        medio.fecha = Date()
        medio.filtro = filtro
        medio.etiquetas = ""
        if let ubicacion {
            medio.latitud = NSNumber(value: ubicacion.0)
            medio.longitud = NSNumber(value: ubicacion.1)
        }
        medio.album = album
        Persistencia.compartida.guardar()
        return medio
    }

    // MARK: Editar y eliminar

    /// Reemplaza el archivo de una foto por su versión editada.
    static func sobrescribirFoto(_ medio: Medio, con imagen: UIImage, filtro: Filtro) throws {
        guard let datos = imagen.jpegData(compressionQuality: 0.9) else { throw ErrorMedio.noSePudoGuardar }
        try datos.write(to: medio.url, options: .atomic)
        medio.filtro = filtro == .original ? medio.filtro : filtro.rawValue
        medio.fecha = medio.fecha // fuerza a Core Data a notificar el cambio
        cache.removeAllObjects()
        Persistencia.compartida.guardar()
    }

    static func eliminar(_ medio: Medio) {
        try? FileManager.default.removeItem(at: medio.url)
        contexto.delete(medio)
        Persistencia.compartida.guardar()
    }

    // MARK: Importar

    /// Copia al almacenamiento de la app una imagen o audio elegido en la app Archivos.
    static func importar(_ externo: URL) throws {
        let acceso = externo.startAccessingSecurityScopedResource()
        defer { if acceso { externo.stopAccessingSecurityScopedResource() } }
        prepararCarpetas()
        let ext = externo.pathExtension.lowercased()
        if ["jpg", "jpeg", "png", "heic"].contains(ext) {
            guard let imagen = UIImage(contentsOfFile: externo.path) else { throw ErrorMedio.formatoNoSoportado }
            try guardarFoto(imagen, filtro: .original, ubicacion: nil)
        } else if ["m4a", "wav", "mp3", "aac", "caf"].contains(ext) {
            let nombre = "Importado_\(marcaDeTiempo()).\(ext)"
            try FileManager.default.copyItem(at: externo, to: carpetaAudios.appendingPathComponent(nombre))
            let duracion = (try? AVAudioPlayer(contentsOf: carpetaAudios.appendingPathComponent(nombre)).duration) ?? 0
            registrarAudio(nombre: nombre, duracion: duracion, ubicacion: nil)
        } else {
            throw ErrorMedio.formatoNoSoportado
        }
    }

    // MARK: Miniaturas

    static func miniatura(de medio: Medio, lado: CGFloat = 200) -> UIImage? {
        let valores = try? medio.url.resourceValues(forKeys: [.contentModificationDateKey])
        let texto = "\(medio.archivo)|\(valores?.contentModificationDate?.timeIntervalSince1970 ?? 0)|\(Int(lado))"
        let clave = SHA256.hash(data: Data(texto.utf8)).map { String(format: "%02x", $0) }.joined()
        if let enMemoria = cache.object(forKey: clave as NSString) { return enMemoria }
        let enDisco = carpetaMiniaturas.appendingPathComponent(clave + ".jpg")
        if let datos = try? Data(contentsOf: enDisco), let imagen = UIImage(data: datos) {
            cache.setObject(imagen, forKey: clave as NSString)
            return imagen
        }
        let opciones: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: lado * 2
        ]
        guard let fuente = CGImageSourceCreateWithURL(medio.url as CFURL, nil),
              let cg = CGImageSourceCreateThumbnailAtIndex(fuente, 0, opciones as CFDictionary) else { return nil }
        let imagen = UIImage(cgImage: cg)
        cache.setObject(imagen, forKey: clave as NSString)
        try? imagen.jpegData(compressionQuality: 0.8)?.write(to: enDisco)
        return imagen
    }

    // MARK: Ayudantes

    private static func marcaDeTiempo() -> String {
        let formato = DateFormatter()
        formato.dateFormat = "yyyyMMdd_HHmmss_SSS"
        return formato.string(from: Date())
    }

    /// Borra archivos y registros (modo de pruebas).
    static func reiniciar() {
        for carpeta in [carpetaFotos, carpetaAudios, carpetaMiniaturas] {
            try? FileManager.default.removeItem(at: carpeta)
        }
        cache.removeAllObjects()
        Persistencia.compartida.borrarTodo()
        prepararCarpetas()
    }
}

enum ErrorMedio: LocalizedError {
    case noSePudoGuardar, formatoNoSoportado, sinCamara, sinMicrofono, permisoDenegado(String)

    var errorDescription: String? {
        switch self {
        case .noSePudoGuardar: return "No se pudo guardar el archivo."
        case .formatoNoSoportado: return "Ese archivo no es una imagen ni un audio compatible."
        case .sinCamara: return "Este dispositivo no tiene cámara disponible."
        case .sinMicrofono: return "No hay micrófono disponible en este dispositivo."
        case .permisoDenegado(let recurso): return "No diste permiso para usar \(recurso). Puedes activarlo en Ajustes › Privacidad."
        }
    }
}
