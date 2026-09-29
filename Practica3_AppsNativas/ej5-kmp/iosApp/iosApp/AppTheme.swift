import SwiftUI
import SharedLogic

/// Temas Guinda (IPN) y Azul (ESCOM). Mismos tonos que Android (ver COLORES.md):
/// en modo oscuro el color principal se aclara para tener contraste sobre fondo oscuro.
/// Los nombres guardados ("GUINDA", "AZUL") son los mismos que usa la app de Android.
enum AppTheme: String, CaseIterable, Identifiable {
    case guinda = "GUINDA"
    case azul = "AZUL"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .guinda: return "Guinda (IPN)"
        case .azul: return "Azul (ESCOM)"
        }
    }

    func primary(_ scheme: ColorScheme) -> Color {
        switch self {
        case .guinda: return scheme == .dark ? Color(hex: 0xD98CB3) : Color(hex: 0x6C1D45)
        case .azul: return scheme == .dark ? Color(hex: 0x8FB4DE) : Color(hex: 0x0D2F5A)
        }
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0
        )
    }
}

// MARK: - Utilidades sobre FileEntry (el modelo viene del módulo compartido de Kotlin)

extension FileEntry {
    /// Extensión en minúsculas ("" para carpetas).
    var fileExtension: String {
        isDirectory ? "" : (name as NSString).pathExtension.lowercased()
    }

    var isImage: Bool {
        ["jpg", "jpeg", "png", "gif", "webp", "bmp", "heic"].contains(fileExtension)
    }

    var isText: Bool {
        ["txt", "md", "log", "json", "kt", "swift", "xml", "csv"].contains(fileExtension)
    }

    /// Ícono (SF Symbols) según el tipo de archivo.
    var iconName: String {
        if isDirectory { return "folder.fill" }
        if isImage { return "photo" }
        if isText { return "doc.text" }
        if ["mp3", "wav", "ogg", "m4a"].contains(fileExtension) { return "music.note" }
        if ["mp4", "mov", "avi", "mkv"].contains(fileExtension) { return "film" }
        if fileExtension == "pdf" { return "doc.richtext" }
        return "doc"
    }

    /// Texto secundario de cada fila: "Carpeta · fecha" o "tamaño · fecha".
    var detailText: String {
        var parts: [String] = []
        parts.append(isDirectory ? "Carpeta" : ByteCountFormatter.string(fromByteCount: sizeBytes, countStyle: .file))
        if lastModifiedEpochMillis > 0 {
            let date = Date(timeIntervalSince1970: TimeInterval(lastModifiedEpochMillis) / 1000.0)
            parts.append(date.formatted(date: .abbreviated, time: .shortened))
        }
        return parts.joined(separator: " · ")
    }
}
