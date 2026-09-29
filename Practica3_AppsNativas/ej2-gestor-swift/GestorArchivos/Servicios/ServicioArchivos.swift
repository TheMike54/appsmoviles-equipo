import Foundation
import UIKit

/// Errores de las operaciones con archivos, con mensajes pensados para el usuario.
enum ErrorArchivo: LocalizedError {
    case yaExiste(String)
    case nombreInvalido
    case fueraDelSandbox
    case noSePudoLeer(String)
    case formatoNoSoportado(String)
    case sistema(String)

    var errorDescription: String? {
        switch self {
        case .yaExiste(let nombre): return "Ya existe un elemento llamado «\(nombre)» en esta carpeta."
        case .nombreInvalido: return "El nombre no puede estar vacío ni contener «/»."
        case .fueraDelSandbox: return "La app no tiene permiso para acceder a esa ubicación."
        case .noSePudoLeer(let nombre): return "No se pudo abrir «\(nombre)». Puede estar dañado o ya no existir."
        case .formatoNoSoportado(let nombre): return "«\(nombre)» tiene un formato que esta app no puede mostrar."
        case .sistema(let mensaje): return mensaje
        }
    }
}

/// Todas las operaciones con el sistema de archivos pasan por aquí (FileManager).
/// Solo se trabaja dentro del contenedor de la app (sandbox) o en ubicaciones que el usuario
/// autorizó con el selector de documentos.
struct ServicioArchivos {
    static let compartido = ServicioArchivos()
    private let fm = FileManager.default

    // MARK: Ubicaciones del sandbox

    var documentos: URL { fm.urls(for: .documentDirectory, in: .userDomainMask)[0] }
    /// Carpeta donde iOS deja los archivos que otras apps "abren con" esta app.
    var inbox: URL { documentos.appendingPathComponent("Inbox", isDirectory: true) }
    var temporal: URL { fm.temporaryDirectory }
    var contenedor: URL { URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true) }

    /// Indica si una URL está dentro del contenedor de la app.
    func estaEnSandbox(_ url: URL) -> Bool {
        url.standardizedFileURL.path.hasPrefix(contenedor.standardizedFileURL.path)
    }

    // MARK: Lectura

    func listar(_ carpeta: URL) throws -> [ElementoArchivo] {
        do {
            let urls = try fm.contentsOfDirectory(
                at: carpeta,
                includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey, .contentTypeKey],
                options: [.skipsHiddenFiles]
            )
            return urls.map(ElementoArchivo.init(url:))
        } catch {
            throw ErrorArchivo.noSePudoLeer(carpeta.lastPathComponent)
        }
    }

    func existe(_ url: URL) -> Bool { fm.fileExists(atPath: url.path) }

    func esCarpeta(_ url: URL) -> Bool {
        var carpeta: ObjCBool = false
        return fm.fileExists(atPath: url.path, isDirectory: &carpeta) && carpeta.boolValue
    }

    // MARK: Gestión

    func crearCarpeta(nombre: String, en carpeta: URL) throws -> URL {
        let destino = try urlValida(nombre: nombre, en: carpeta)
        try ejecutar { try fm.createDirectory(at: destino, withIntermediateDirectories: false) }
        return destino
    }

    func renombrar(_ url: URL, a nombre: String) throws -> URL {
        let destino = try urlValida(nombre: nombre, en: url.deletingLastPathComponent())
        try ejecutar { try fm.moveItem(at: url, to: destino) }
        return destino
    }

    func copiar(_ url: URL, a carpeta: URL) throws -> URL {
        let destino = nombreLibre(para: url.lastPathComponent, en: carpeta)
        try ejecutar { try fm.copyItem(at: url, to: destino) }
        return destino
    }

    func mover(_ url: URL, a carpeta: URL) throws -> URL {
        let destino = carpeta.appendingPathComponent(url.lastPathComponent)
        if fm.fileExists(atPath: destino.path) { throw ErrorArchivo.yaExiste(url.lastPathComponent) }
        try ejecutar { try fm.moveItem(at: url, to: destino) }
        return destino
    }

    func eliminar(_ url: URL) throws {
        try ejecutar { try fm.removeItem(at: url) }
    }

    /// Copia al sandbox un archivo elegido con el selector de documentos.
    func importar(_ externo: URL, a carpeta: URL) throws -> URL {
        let acceso = externo.startAccessingSecurityScopedResource()
        defer { if acceso { externo.stopAccessingSecurityScopedResource() } }
        return try copiar(externo, a: carpeta)
    }

    // MARK: Ayudantes

    private func urlValida(nombre: String, en carpeta: URL) throws -> URL {
        let limpio = nombre.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !limpio.isEmpty, !limpio.contains("/") else { throw ErrorArchivo.nombreInvalido }
        let destino = carpeta.appendingPathComponent(limpio)
        guard !fm.fileExists(atPath: destino.path) else { throw ErrorArchivo.yaExiste(limpio) }
        return destino
    }

    /// Si ya existe un archivo con ese nombre, agrega " copia", " copia 2", etc.
    private func nombreLibre(para nombre: String, en carpeta: URL) -> URL {
        let base = (nombre as NSString).deletingPathExtension
        let ext = (nombre as NSString).pathExtension
        var candidato = carpeta.appendingPathComponent(nombre)
        var n = 1
        while fm.fileExists(atPath: candidato.path) {
            let sufijo = n == 1 ? " copia" : " copia \(n)"
            let nuevo = ext.isEmpty ? base + sufijo : "\(base)\(sufijo).\(ext)"
            candidato = carpeta.appendingPathComponent(nuevo)
            n += 1
        }
        return candidato
    }

    private func ejecutar(_ operacion: () throws -> Void) throws {
        do { try operacion() } catch let error as ErrorArchivo { throw error } catch {
            throw ErrorArchivo.sistema(error.localizedDescription)
        }
    }
}
