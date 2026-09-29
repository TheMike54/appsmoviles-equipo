import Foundation
import UniformTypeIdentifiers

/// Un archivo o carpeta tal como se muestra en la lista.
struct ElementoArchivo: Identifiable, Hashable {
    let url: URL
    let nombre: String
    let esCarpeta: Bool
    let tamano: Int64
    let fechaModificacion: Date
    let tipo: UTType?

    var id: URL { url }

    /// Categoría del archivo según su UTType; decide el visor y el ícono.
    var categoria: Categoria {
        if esCarpeta { return .carpeta }
        guard let tipo else { return .otro }
        if tipo.conforms(to: .image) { return .imagen }
        if tipo.conforms(to: .pdf) { return .pdf }
        if tipo.conforms(to: .sourceCode) || tipo.conforms(to: .json) { return .codigo }
        if tipo.conforms(to: .text) || tipo.conforms(to: .plainText) { return .texto }
        if tipo.conforms(to: .audio) { return .audio }
        if tipo.conforms(to: .movie) { return .video }
        if tipo.conforms(to: .archive) { return .comprimido }
        return .otro
    }

    /// Nombre del símbolo SF que representa el tipo de archivo.
    var icono: String { categoria.icono }

    /// Texto secundario: número de elementos no se calcula para no leer cada carpeta.
    var detalle: String {
        let fecha = fechaModificacion.formatted(date: .abbreviated, time: .shortened)
        if esCarpeta { return "Carpeta · \(fecha)" }
        let tam = ByteCountFormatter.string(fromByteCount: tamano, countStyle: .file)
        return "\(tam) · \(fecha)"
    }

    enum Categoria {
        case carpeta, imagen, pdf, codigo, texto, audio, video, comprimido, otro

        var icono: String {
            switch self {
            case .carpeta: return "folder.fill"
            case .imagen: return "photo"
            case .pdf: return "doc.richtext"
            case .codigo: return "chevron.left.forwardslash.chevron.right"
            case .texto: return "doc.text"
            case .audio: return "waveform"
            case .video: return "film"
            case .comprimido: return "doc.zipper"
            case .otro: return "doc"
            }
        }
    }

    /// Construye el elemento leyendo los atributos del sistema de archivos.
    init(url: URL) {
        let valores = try? url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey, .contentTypeKey])
        self.url = url
        // El sistema de archivos guarda los acentos descompuestos ("o" + "´"); se normalizan
        // a la forma compuesta ("ó") para mostrarlos, buscarlos y compararlos correctamente.
        self.nombre = url.lastPathComponent.precomposedStringWithCanonicalMapping
        self.esCarpeta = valores?.isDirectory ?? false
        self.tamano = Int64(valores?.fileSize ?? 0)
        self.fechaModificacion = valores?.contentModificationDate ?? .distantPast
        self.tipo = valores?.contentType ?? UTType(filenameExtension: url.pathExtension)
    }
}

/// Criterios de ordenamiento de la lista.
enum Orden: String, CaseIterable, Identifiable {
    case nombre, fecha, tamano

    var id: String { rawValue }

    var titulo: String {
        switch self {
        case .nombre: return "Nombre"
        case .fecha: return "Fecha"
        case .tamano: return "Tamaño"
        }
    }

    /// Ordena dejando siempre las carpetas primero.
    func ordenar(_ elementos: [ElementoArchivo], ascendente: Bool) -> [ElementoArchivo] {
        elementos.sorted { a, b in
            if a.esCarpeta != b.esCarpeta { return a.esCarpeta }
            let resultado: Bool
            switch self {
            case .nombre: resultado = a.nombre.localizedStandardCompare(b.nombre) == .orderedAscending
            case .fecha: resultado = a.fechaModificacion < b.fechaModificacion
            case .tamano: resultado = a.tamano < b.tamano
            }
            return ascendente ? resultado : !resultado
        }
    }
}
