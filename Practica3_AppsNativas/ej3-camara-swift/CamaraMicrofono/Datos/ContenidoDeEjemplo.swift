import UIKit
import AVFoundation

/// Crea contenido de ejemplo la primera vez que se abre la app (dos fotos, una grabación
/// y un álbum), para poder usar la galería y el reproductor sin conexión y aunque el
/// dispositivo no tenga cámara ni micrófono.
enum ContenidoDeEjemplo {
    private static let clave = "contenidoDeEjemploCreado"

    static func crearSiHaceFalta() {
        guard !UserDefaults.standard.bool(forKey: clave) else { return }
        AlmacenMedios.prepararCarpetas()
        let contexto = Persistencia.compartida.contexto

        let album = Album(context: contexto)
        album.id = UUID()
        album.nombre = "ESCOM"
        album.fecha = Date()

        if let foto = try? AlmacenMedios.guardarFoto(imagen(titulo: "ESCOM", colores: [.systemIndigo, .systemTeal]),
                                                     filtro: .original, ubicacion: (19.5046, -99.1468), album: album) {
            foto.etiquetas = "escuela, ejemplo"
        }
        if let foto = try? AlmacenMedios.guardarFoto(imagen(titulo: "IPN", colores: [.systemPink, .systemOrange]),
                                                     filtro: .original, ubicacion: (19.4990, -99.1346)) {
            foto.etiquetas = "ejemplo"
        }
        if let url = try? tono() {
            let duracion = (try? AVAudioPlayer(contentsOf: url).duration) ?? 0
            let audio = AlmacenMedios.registrarAudio(nombre: url.lastPathComponent, duracion: duracion, ubicacion: nil)
            audio.etiquetas = "tono, ejemplo"
            audio.album = album
        }
        Persistencia.compartida.guardar()
        UserDefaults.standard.set(true, forKey: clave)
    }

    static func reiniciar() {
        UserDefaults.standard.removeObject(forKey: clave)
        UserDefaults.standard.removeObject(forKey: "tema")
        AlmacenMedios.reiniciar()
    }

    private static func imagen(titulo: String, colores: [UIColor]) -> UIImage {
        let tam = CGSize(width: 1200, height: 900)
        return UIGraphicsImageRenderer(size: tam).image { ctx in
            let degradado = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                       colors: colores.map(\.cgColor) as CFArray, locations: [0, 1])!
            ctx.cgContext.drawLinearGradient(degradado, start: .zero, end: CGPoint(x: tam.width, y: tam.height), options: [])
            let atributos: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 180, weight: .black),
                                                            .foregroundColor: UIColor.white.withAlphaComponent(0.9)]
            let medida = titulo.size(withAttributes: atributos)
            titulo.draw(at: CGPoint(x: (tam.width - medida.width) / 2, y: (tam.height - medida.height) / 2), withAttributes: atributos)
        }
    }

    /// Genera un tono de 3 segundos (La 440 Hz con desvanecimiento) en WAV.
    private static func tono() throws -> URL {
        let url = AlmacenMedios.carpetaAudios.appendingPathComponent("Tono de ejemplo.wav")
        let frecuencia = 44_100.0
        let formato = AVAudioFormat(standardFormatWithSampleRate: frecuencia, channels: 1)!
        let cuadros = AVAudioFrameCount(frecuencia * 3)
        let buffer = AVAudioPCMBuffer(pcmFormat: formato, frameCapacity: cuadros)!
        buffer.frameLength = cuadros
        let datos = buffer.floatChannelData![0]
        for i in 0..<Int(cuadros) {
            let t = Double(i) / frecuencia
            datos[i] = Float(sin(2 * .pi * 440 * t) * 0.4 * max(0, 1 - t / 3))
        }
        let archivo = try AVAudioFile(forWriting: url, settings: formato.settings)
        try archivo.write(from: buffer)
        return url
    }
}
