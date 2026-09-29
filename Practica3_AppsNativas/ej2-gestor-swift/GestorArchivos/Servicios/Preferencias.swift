import Foundation
import Observation

/// Preferencias y datos persistentes de la sesión, guardados en UserDefaults:
/// tema, criterio de orden, última carpeta visitada, historial de recientes y favoritos.
///
/// Las rutas se guardan relativas al contenedor de la app, porque la ruta absoluta del
/// sandbox cambia cada vez que la app se reinstala.
@Observable
final class Preferencias {
    private let defaults = UserDefaults.standard
    private let maxRecientes = 20

    var tema: Tema { didSet { defaults.set(tema.rawValue, forKey: "tema") } }
    var orden: Orden { didSet { defaults.set(orden.rawValue, forKey: "orden") } }
    var ascendente: Bool { didSet { defaults.set(ascendente, forKey: "ascendente") } }
    var enCuadricula: Bool { didSet { defaults.set(enCuadricula, forKey: "enCuadricula") } }
    private(set) var ultimaCarpeta: String? { didSet { defaults.set(ultimaCarpeta, forKey: "ultimaCarpeta") } }
    private(set) var recientes: [String] { didSet { defaults.set(recientes, forKey: "recientes") } }
    private(set) var favoritos: [String] { didSet { defaults.set(favoritos, forKey: "favoritos") } }

    init() {
        tema = Tema(rawValue: defaults.string(forKey: "tema") ?? "") ?? .guinda
        orden = Orden(rawValue: defaults.string(forKey: "orden") ?? "") ?? .nombre
        ascendente = defaults.object(forKey: "ascendente") as? Bool ?? true
        enCuadricula = defaults.bool(forKey: "enCuadricula")
        ultimaCarpeta = defaults.string(forKey: "ultimaCarpeta")
        recientes = defaults.stringArray(forKey: "recientes") ?? []
        favoritos = defaults.stringArray(forKey: "favoritos") ?? []
    }

    // MARK: Conversión ruta relativa <-> URL

    private var base: String { ServicioArchivos.compartido.contenedor.standardizedFileURL.path }

    func relativa(_ url: URL) -> String {
        let ruta = url.standardizedFileURL.path
        return ruta.hasPrefix(base) ? String(ruta.dropFirst(base.count)) : ruta
    }

    func url(de relativa: String) -> URL {
        relativa.hasPrefix("/") && !relativa.hasPrefix(base) && FileManager.default.fileExists(atPath: relativa)
            ? URL(fileURLWithPath: relativa)
            : URL(fileURLWithPath: base + relativa)
    }

    // MARK: Última carpeta

    func recordarCarpeta(_ url: URL) { ultimaCarpeta = relativa(url) }

    var urlUltimaCarpeta: URL? {
        guard let ultimaCarpeta else { return nil }
        let url = url(de: ultimaCarpeta)
        return ServicioArchivos.compartido.esCarpeta(url) ? url : nil
    }

    // MARK: Recientes

    func registrarReciente(_ url: URL) {
        let ruta = relativa(url)
        recientes.removeAll { $0 == ruta }
        recientes.insert(ruta, at: 0)
        if recientes.count > maxRecientes { recientes.removeLast(recientes.count - maxRecientes) }
    }

    func limpiarRecientes() { recientes = [] }

    /// Solo devuelve los recientes que todavía existen.
    var urlsRecientes: [URL] {
        recientes.map(url(de:)).filter { ServicioArchivos.compartido.existe($0) }
    }

    // MARK: Favoritos

    func esFavorito(_ url: URL) -> Bool { favoritos.contains(relativa(url)) }

    func alternarFavorito(_ url: URL) {
        let ruta = relativa(url)
        if let i = favoritos.firstIndex(of: ruta) { favoritos.remove(at: i) } else { favoritos.append(ruta) }
    }

    var urlsFavoritos: [URL] {
        favoritos.map(url(de:)).filter { ServicioArchivos.compartido.existe($0) }
    }

    /// Mantiene recientes y favoritos al día cuando un elemento se renombra, mueve o elimina.
    func actualizarRuta(de anterior: URL, a nueva: URL?) {
        let viejo = relativa(anterior)
        let nuevo = nueva.map(relativa)
        func reemplazar(_ lista: [String]) -> [String] {
            lista.compactMap { ruta in
                guard ruta == viejo || ruta.hasPrefix(viejo + "/") else { return ruta }
                guard let nuevo else { return nil }
                return nuevo + ruta.dropFirst(viejo.count)
            }
        }
        recientes = reemplazar(recientes)
        favoritos = reemplazar(favoritos)
        if let ultimaCarpeta, ultimaCarpeta == viejo || ultimaCarpeta.hasPrefix(viejo + "/") {
            self.ultimaCarpeta = nuevo.map { $0 + ultimaCarpeta.dropFirst(viejo.count) }
        }
    }
}
