import UIKit

/// Crea archivos de ejemplo la primera vez que se abre la app, para que el gestor tenga
/// contenido que explorar sin conexión a internet (texto, código, imágenes, PDF y un archivo dañado).
enum ArchivosDeEjemplo {
    private static let clave = "archivosDeEjemploCreados"

    static func crearSiHaceFalta() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: clave) else { return }
        let servicio = ServicioArchivos.compartido
        let docs = servicio.documentos
        let fm = FileManager.default

        for carpeta in ["Notas", "Código", "Imágenes", "Documentos"] {
            try? fm.createDirectory(at: docs.appendingPathComponent(carpeta), withIntermediateDirectories: true)
        }

        escribir("""
        Bienvenido al Gestor de Archivos.

        Esta app explora las carpetas del sandbox de iOS (Documents, Inbox y tmp).
        Mantén presionado un archivo para ver sus opciones o desliza para eliminarlo.
        """, en: docs.appendingPathComponent("Bienvenida.txt"))

        escribir("""
        # Apuntes de Apps Móviles

        - **SwiftUI** construye la interfaz de forma declarativa.
        - `FileManager` gestiona archivos y carpetas.
        - Quick Look muestra vistas previas nativas.
        """, en: docs.appendingPathComponent("Notas/Apuntes.md"))

        escribir("""
        {
          "app": "Gestor de Archivos",
          "temas": ["guinda", "azul"],
          "sinConexion": true
        }
        """, en: docs.appendingPathComponent("Código/configuracion.json"))

        escribir("""
        import Foundation

        // Ejemplo: lista los archivos de Documents
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let archivos = try FileManager.default.contentsOfDirectory(atPath: docs.path)
        print(archivos)
        """, en: docs.appendingPathComponent("Código/Ejemplo.swift"))

        guardarImagen(paisaje(), en: docs.appendingPathComponent("Imágenes/Paisaje.png"))
        guardarImagen(logo(texto: "IPN", color: Tema.guinda.uiColor), en: docs.appendingPathComponent("Imágenes/Logo IPN.png"))
        guardarImagen(logo(texto: "ESCOM", color: Tema.azul.uiColor), en: docs.appendingPathComponent("Imágenes/Logo ESCOM.png"))
        try? pdf().write(to: docs.appendingPathComponent("Documentos/Guía de uso.pdf"))

        // Archivo con extensión de imagen pero contenido inválido: sirve para probar el manejo de errores.
        try? Data("esto no es una imagen".utf8).write(to: docs.appendingPathComponent("Imágenes/foto_dañada.png"))

        escribir("Archivo temporal de ejemplo. iOS puede borrar esta carpeta cuando necesite espacio.",
                 en: servicio.temporal.appendingPathComponent("temporal.txt"))

        defaults.set(true, forKey: clave)
    }

    /// Borra el contenido de Documents y tmp y las preferencias guardadas.
    static func reiniciar() {
        let fm = FileManager.default
        let servicio = ServicioArchivos.compartido
        for carpeta in [servicio.documentos, servicio.temporal] {
            for url in (try? fm.contentsOfDirectory(at: carpeta, includingPropertiesForKeys: nil)) ?? [] {
                try? fm.removeItem(at: url)
            }
        }
        let defaults = UserDefaults.standard
        for clave in ["tema", "orden", "ascendente", "enCuadricula", "ultimaCarpeta", "recientes",
                      "favoritos", "marcadoresExternos", clave] {
            defaults.removeObject(forKey: clave)
        }
    }

    private static func escribir(_ texto: String, en url: URL) {
        try? texto.write(to: url, atomically: true, encoding: .utf8)
    }

    private static func guardarImagen(_ imagen: UIImage, en url: URL) {
        try? imagen.pngData()?.write(to: url)
    }

    private static func paisaje() -> UIImage {
        let tam = CGSize(width: 1200, height: 800)
        return UIGraphicsImageRenderer(size: tam).image { ctx in
            let colores = [UIColor.systemTeal.cgColor, UIColor.systemIndigo.cgColor] as CFArray
            let degradado = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colores, locations: [0, 1])!
            ctx.cgContext.drawLinearGradient(degradado, start: .zero, end: CGPoint(x: 0, y: tam.height), options: [])
            UIColor.systemYellow.setFill()
            ctx.cgContext.fillEllipse(in: CGRect(x: 850, y: 120, width: 180, height: 180))
            UIColor(red: 0.1, green: 0.35, blue: 0.2, alpha: 1).setFill()
            let montana = UIBezierPath()
            montana.move(to: CGPoint(x: 0, y: 800))
            montana.addLine(to: CGPoint(x: 350, y: 380))
            montana.addLine(to: CGPoint(x: 650, y: 650))
            montana.addLine(to: CGPoint(x: 900, y: 450))
            montana.addLine(to: CGPoint(x: 1200, y: 800))
            montana.close()
            montana.fill()
        }
    }

    private static func logo(texto: String, color: UIColor) -> UIImage {
        let tam = CGSize(width: 600, height: 600)
        let claro = color.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
        return UIGraphicsImageRenderer(size: tam).image { _ in
            claro.setFill()
            UIBezierPath(roundedRect: CGRect(origin: .zero, size: tam), cornerRadius: 120).fill()
            let atributos: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 140, weight: .heavy),
                .foregroundColor: UIColor.white
            ]
            let medida = texto.size(withAttributes: atributos)
            texto.draw(at: CGPoint(x: (tam.width - medida.width) / 2, y: (tam.height - medida.height) / 2), withAttributes: atributos)
        }
    }

    private static func pdf() -> Data {
        let pagina = CGRect(x: 0, y: 0, width: 612, height: 792)
        return UIGraphicsPDFRenderer(bounds: pagina).pdfData { ctx in
            ctx.beginPage()
            let titulo: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 28)]
            let cuerpo: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 16)]
            "Guía de uso — Gestor de Archivos".draw(at: CGPoint(x: 50, y: 60), withAttributes: titulo)
            """
            1. Toca una carpeta para entrar y un archivo para abrirlo.
            2. Mantén presionado un elemento para renombrarlo, copiarlo, moverlo,
               compartirlo, marcarlo como favorito o eliminarlo.
            3. Desliza hacia la izquierda para eliminar.
            4. Jala hacia abajo para actualizar la carpeta.
            5. Usa el botón + para crear carpetas o importar archivos.

            Documento generado por la app como ejemplo de vista previa con Quick Look.
            """.draw(in: CGRect(x: 50, y: 120, width: 512, height: 600), withAttributes: cuerpo)
        }
    }
}
