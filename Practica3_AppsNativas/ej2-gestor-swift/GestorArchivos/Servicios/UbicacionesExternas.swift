import Foundation
import Observation

/// Carpetas fuera del sandbox (por ejemplo, en la app Archivos o iCloud Drive) que el usuario
/// autorizó con el selector de documentos.
///
/// iOS solo da acceso temporal a esas carpetas; para conservarlo entre sesiones se guarda un
/// *security-scoped bookmark* y, antes de leerla, se llama a `startAccessingSecurityScopedResource()`.
@Observable
final class UbicacionesExternas {
    struct Ubicacion: Identifiable, Hashable {
        let id: UUID
        let nombre: String
        let url: URL
    }

    private let clave = "marcadoresExternos"
    private(set) var ubicaciones: [Ubicacion] = []
    /// URLs a las que ya se les pidió acceso en esta sesión.
    private var accesosAbiertos: Set<URL> = []

    init() { cargar() }

    /// Guarda el marcador de una carpeta elegida por el usuario.
    func agregar(_ url: URL) throws {
        let acceso = url.startAccessingSecurityScopedResource()
        defer { if acceso { url.stopAccessingSecurityScopedResource() } }
        let marcador = try url.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil)
        var guardados = marcadores()
        guardados[UUID().uuidString] = marcador
        UserDefaults.standard.set(guardados, forKey: clave)
        cargar()
    }

    func quitar(_ ubicacion: Ubicacion) {
        var guardados = marcadores()
        guardados.removeValue(forKey: ubicacion.id.uuidString)
        UserDefaults.standard.set(guardados, forKey: clave)
        if accesosAbiertos.remove(ubicacion.url) != nil { ubicacion.url.stopAccessingSecurityScopedResource() }
        cargar()
    }

    /// Abre el acceso a la carpeta externa (una vez por sesión) antes de listarla.
    func abrirAcceso(_ url: URL) -> Bool {
        if accesosAbiertos.contains(url) { return true }
        guard url.startAccessingSecurityScopedResource() else { return false }
        accesosAbiertos.insert(url)
        return true
    }

    /// Indica si una URL pertenece a alguna de las ubicaciones externas autorizadas.
    func contiene(_ url: URL) -> Bool {
        ubicaciones.contains { url.standardizedFileURL.path.hasPrefix($0.url.standardizedFileURL.path) }
    }

    private func marcadores() -> [String: Data] {
        UserDefaults.standard.dictionary(forKey: clave) as? [String: Data] ?? [:]
    }

    /// Resuelve los marcadores guardados; si alguno quedó obsoleto, se regenera.
    private func cargar() {
        var resultado: [Ubicacion] = []
        var guardados = marcadores()
        for (id, datos) in guardados {
            var obsoleto = false
            guard let uuid = UUID(uuidString: id),
                  let url = try? URL(resolvingBookmarkData: datos, options: [], relativeTo: nil, bookmarkDataIsStale: &obsoleto) else {
                guardados.removeValue(forKey: id)
                continue
            }
            if obsoleto, let nuevo = try? url.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil) {
                guardados[id] = nuevo
            }
            resultado.append(Ubicacion(id: uuid, nombre: url.lastPathComponent, url: url))
        }
        UserDefaults.standard.set(guardados, forKey: clave)
        ubicaciones = resultado.sorted { $0.nombre.localizedStandardCompare($1.nombre) == .orderedAscending }
    }
}
