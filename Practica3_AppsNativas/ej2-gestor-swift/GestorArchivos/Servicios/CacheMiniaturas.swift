import UIKit
import ImageIO
import CryptoKit

/// Caché de miniaturas de imágenes en dos niveles:
/// 1. memoria (NSCache), para la sesión actual;
/// 2. disco (Library/Caches/Miniaturas), para no regenerarlas al volver a abrir la app.
/// La clave incluye la fecha de modificación, así una imagen editada genera una miniatura nueva.
actor CacheMiniaturas {
    static let compartida = CacheMiniaturas()

    private let memoria = NSCache<NSString, UIImage>()
    private let carpeta: URL

    init() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        carpeta = caches.appendingPathComponent("Miniaturas", isDirectory: true)
        try? FileManager.default.createDirectory(at: carpeta, withIntermediateDirectories: true)
    }

    func miniatura(de elemento: ElementoArchivo, lado: CGFloat = 160) -> UIImage? {
        let clave = self.clave(elemento, lado: lado)
        if let enMemoria = memoria.object(forKey: clave as NSString) { return enMemoria }

        let archivo = carpeta.appendingPathComponent(clave + ".jpg")
        if let datos = try? Data(contentsOf: archivo), let imagen = UIImage(data: datos) {
            memoria.setObject(imagen, forKey: clave as NSString)
            return imagen
        }

        // ImageIO reduce la imagen sin cargarla completa en memoria.
        let opciones: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: lado * 2
        ]
        guard let fuente = CGImageSourceCreateWithURL(elemento.url as CFURL, nil),
              let cg = CGImageSourceCreateThumbnailAtIndex(fuente, 0, opciones as CFDictionary) else {
            return nil
        }
        let imagen = UIImage(cgImage: cg)
        memoria.setObject(imagen, forKey: clave as NSString)
        try? imagen.jpegData(compressionQuality: 0.8)?.write(to: archivo)
        return imagen
    }

    /// Borra la caché en memoria y en disco. Devuelve los bytes liberados.
    @discardableResult
    func limpiar() -> Int64 {
        memoria.removeAllObjects()
        let fm = FileManager.default
        let archivos = (try? fm.contentsOfDirectory(at: carpeta, includingPropertiesForKeys: [.fileSizeKey])) ?? []
        var total: Int64 = 0
        for archivo in archivos {
            total += Int64((try? archivo.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
            try? fm.removeItem(at: archivo)
        }
        return total
    }

    func tamanoEnDisco() -> Int64 {
        let archivos = (try? FileManager.default.contentsOfDirectory(at: carpeta, includingPropertiesForKeys: [.fileSizeKey])) ?? []
        return archivos.reduce(0) { $0 + Int64((try? $1.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0) }
    }

    private func clave(_ elemento: ElementoArchivo, lado: CGFloat) -> String {
        let texto = "\(elemento.url.path)|\(elemento.fechaModificacion.timeIntervalSince1970)|\(Int(lado))"
        return SHA256.hash(data: Data(texto.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}
