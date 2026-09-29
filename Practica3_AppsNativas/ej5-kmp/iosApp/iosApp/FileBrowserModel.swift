import SwiftUI
import SharedLogic

enum AppTab: Hashable {
    case explorar, recientes, favoritos
}

/// Copiar o mover una entrada: espera a que el usuario elija la carpeta de destino.
struct TransferRequest: Identifiable {
    let id = UUID()
    let entry: FileEntry
    let move: Bool
}

/// Estado de la app en iOS. Toda la lógica de archivos (PlatformFileSystem), las
/// preferencias (AppSettings, DataStore) y el ordenamiento (sortedFor) vienen del módulo
/// compartido de Kotlin (framework SharedLogic); aquí solo se conecta con SwiftUI.
/// Las claves guardadas son las mismas que usa la versión de Android.
@MainActor
final class FileBrowserModel: ObservableObject {

    private let fs = PlatformFileSystem.shared
    let rootPath: String

    // Navegación
    @Published var selectedTab: AppTab = .explorar
    @Published var navPath: [String] = [] {
        didSet { saveLastPath() }
    }
    /// Se incrementa para que las listas vuelvan a leer el disco.
    @Published var refreshToken = 0

    // Preferencias (persistentes)
    @Published var theme: AppTheme = .guinda
    @Published var sortOrder: SharedLogic.SortOrder = .nombre
    @Published var ascending = true

    // Favoritos y recientes (persistentes)
    @Published private(set) var favoritePaths: [String] = []
    @Published private(set) var recentPaths: [String] = []

    // Diálogos
    @Published var inputText = ""
    @Published var showNewFolder = false
    @Published var showRename = false
    @Published var showDelete = false
    @Published var showImporter = false
    @Published var transfer: TransferRequest?
    @Published var message: String?
    private(set) var renameTarget: FileEntry?
    private(set) var deleteTarget: FileEntry?

    private enum Key {
        static let theme = "theme"
        static let sortOrder = "sortOrder"
        static let sortAscending = "sortAscending"
        static let lastPath = "lastPath"
        static let favorites = "favorites"
        static let recents = "recents"
    }

    private let maxRecents = 20

    init() {
        rootPath = PlatformFileSystem.shared.defaultRootPath()
        Task { await loadSettings() }
    }

    // MARK: - Preferencias

    private func loadSettings() async {
        let settings = AppSettings.shared

        if let saved = try? await settings.getString(key: Key.theme), let restored = AppTheme(rawValue: saved) {
            theme = restored
        }
        if let saved = try? await settings.getString(key: Key.sortOrder) {
            switch saved {
            case "FECHA": sortOrder = .fecha
            case "TAMANO": sortOrder = .tamano
            default: sortOrder = .nombre
            }
        }
        if let saved = try? await settings.getString(key: Key.sortAscending) {
            ascending = (saved != "false")
        }
        favoritePaths = (try? await settings.getList(key: Key.favorites)) ?? []
        recentPaths = (try? await settings.getList(key: Key.recents)) ?? []

        // Primera vez: archivos de ejemplo para que el explorador no arranque vacío.
        _ = try? await SampleContent.shared.seedIfNeeded()
        refreshToken += 1

        // Última carpeta visitada: solo si sigue existiendo y está dentro de la raíz.
        if let last = try? await settings.getString(key: Key.lastPath) {
            restoreLastPath(last)
        }
    }

    func setTheme(_ newTheme: AppTheme) {
        theme = newTheme
        save(Key.theme, newTheme.rawValue)
    }

    func setSort(_ order: SharedLogic.SortOrder) {
        sortOrder = order
        save(Key.sortOrder, order.name)
    }

    func setAscending(_ value: Bool) {
        ascending = value
        save(Key.sortAscending, value ? "true" : "false")
    }

    private func save(_ key: String, _ value: String) {
        Task { _ = try? await AppSettings.shared.putString(key: key, value: value) }
    }

    private func saveLists() {
        let favorites = favoritePaths
        let recents = recentPaths
        Task {
            _ = try? await AppSettings.shared.putList(key: Key.favorites, values: favorites)
            _ = try? await AppSettings.shared.putList(key: Key.recents, values: recents)
        }
    }

    private func saveLastPath() {
        save(Key.lastPath, currentDirectory)
    }

    // MARK: - Navegación

    var currentDirectory: String { navPath.last ?? rootPath }

    /// Lista de rutas desde la raíz hasta [path] (lo que necesita NavigationStack).
    private func chain(to path: String) -> [String] {
        guard path.hasPrefix(rootPath + "/") else { return [] }
        var result: [String] = []
        var current = rootPath
        for part in path.dropFirst(rootPath.count + 1).split(separator: "/") {
            current += "/\(part)"
            result.append(current)
        }
        return result
    }

    private func restoreLastPath(_ saved: String) {
        var isDir: ObjCBool = false
        guard saved.hasPrefix(rootPath + "/"),
              FileManager.default.fileExists(atPath: saved, isDirectory: &isDir),
              isDir.boolValue else { return }
        navPath = chain(to: saved)
    }

    /// Desde Recientes o Favoritos: abre esa carpeta en la pestaña Explorar.
    func goToFolder(_ path: String) {
        selectedTab = .explorar
        navPath = chain(to: path)
    }

    // MARK: - Lectura del disco

    private func sorted(_ list: [FileEntry]) -> [FileEntry] {
        // Función de extensión de Kotlin (SortOrder.kt): carpetas primero, luego el criterio.
        SortOrderKt.sortedFor(list, order: sortOrder, ascending: ascending)
    }

    func entries(in path: String) -> [FileEntry] {
        sorted(fs.listEntries(path: path))
    }

    func folders(in path: String) -> [FileEntry] {
        guard !path.isEmpty else { return [] }
        return fs.listEntries(path: path)
            .filter { $0.isDirectory }
            .sorted { $0.name.lowercased() < $1.name.lowercased() }
    }

    func readText(_ entry: FileEntry) -> String {
        let text = fs.readTextFile(path: entry.path)
        return text.isEmpty ? "(archivo vacío o no legible)" : String(text.prefix(200_000))
    }

    private func entry(for path: String) -> FileEntry? {
        let parent = (path as NSString).deletingLastPathComponent
        return fs.listEntries(path: parent).first { $0.path == path }
    }

    var favorites: [FileEntry] { favoritePaths.compactMap { entry(for: $0) } }
    var recents: [FileEntry] { recentPaths.compactMap { entry(for: $0) } }

    func isFavorite(_ entry: FileEntry) -> Bool { favoritePaths.contains(entry.path) }

    // MARK: - Favoritos y recientes

    func toggleFavorite(_ entry: FileEntry) {
        if isFavorite(entry) {
            favoritePaths.removeAll { $0 == entry.path }
        } else {
            favoritePaths.insert(entry.path, at: 0)
        }
        saveLists()
    }

    func registerRecent(_ entry: FileEntry) {
        recentPaths.removeAll { $0 == entry.path }
        recentPaths.insert(entry.path, at: 0)
        recentPaths = Array(recentPaths.prefix(maxRecents))
        saveLists()
    }

    func clearRecents() {
        recentPaths = []
        saveLists()
    }

    /// Cuando un archivo cambia de ruta (renombrar/mover) o se borra (newPath = nil).
    private func remapPaths(_ old: String, _ new: String?) {
        func map(_ path: String) -> String? {
            if path == old { return new }
            if path.hasPrefix(old + "/") { return new.map { $0 + String(path.dropFirst(old.count)) } }
            return path
        }
        favoritePaths = favoritePaths.compactMap { map($0) }
        recentPaths = recentPaths.compactMap { map($0) }
        saveLists()
    }

    // MARK: - Gestión de archivos

    private func isValidName(_ name: String) -> Bool {
        !name.isEmpty && !name.contains("/") && name != "." && name != ".."
    }

    func askNewFolder() {
        inputText = ""
        showNewFolder = true
    }

    func createFolder(named raw: String) {
        let name = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValidName(name) else { message = "Nombre no válido"; return }
        if fs.createDirectory(parentPath: currentDirectory, name: name) {
            message = "Carpeta \"\(name)\" creada"
        } else {
            message = "No se pudo crear \"\(name)\" (¿ya existe?)"
        }
        refreshToken += 1
    }

    func askRename(_ entry: FileEntry) {
        renameTarget = entry
        inputText = entry.name
        showRename = true
    }

    func confirmRename() {
        guard let entry = renameTarget else { return }
        let newName = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValidName(newName) else { message = "Nombre no válido"; return }
        if newName == entry.name { return }

        let parent = (entry.path as NSString).deletingLastPathComponent
        if fs.listEntries(path: parent).contains(where: { $0.name == newName }) {
            message = "Ya existe \"\(newName)\" en esta carpeta"
            return
        }
        if fs.rename(path: entry.path, newName: newName) {
            remapPaths(entry.path, "\(parent)/\(newName)")
        } else {
            message = "No se pudo renombrar"
        }
        refreshToken += 1
    }

    func askDelete(_ entry: FileEntry) {
        deleteTarget = entry
        showDelete = true
    }

    func confirmDelete() {
        guard let entry = deleteTarget else { return }
        if fs.delete(path: entry.path) {
            remapPaths(entry.path, nil)
            message = "\"\(entry.name)\" eliminado"
        } else {
            message = "No se pudo eliminar \"\(entry.name)\""
        }
        refreshToken += 1
    }

    func performTransfer(_ entry: FileEntry, to destinationDir: String, move: Bool) {
        let verb = move ? "mover" : "copiar"
        let insideItself = entry.isDirectory &&
            (destinationDir == entry.path || destinationDir.hasPrefix(entry.path + "/"))

        if insideItself {
            message = "No se puede \(verb) una carpeta dentro de sí misma"
        } else if fs.listEntries(path: destinationDir).contains(where: { $0.name == entry.name }) {
            message = "Ya existe \"\(entry.name)\" en la carpeta de destino"
        } else if move {
            if fs.move(sourcePath: entry.path, destinationDirPath: destinationDir) {
                remapPaths(entry.path, "\(destinationDir)/\(entry.name)")
                message = "\"\(entry.name)\" movido"
            } else {
                message = "No se pudo mover"
            }
        } else {
            message = fs.doCopy(sourcePath: entry.path, destinationDirPath: destinationDir)
                ? "\"\(entry.name)\" copiado"
                : "No se pudo copiar"
        }
        refreshToken += 1
    }

    /// Importar: copia el archivo elegido en el selector de documentos a la carpeta actual.
    /// Se pide acceso temporal con security-scoped resource porque el archivo está fuera del sandbox.
    func importFile(from url: URL) {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }

        let target = uniqueURL(in: currentDirectory, name: url.lastPathComponent)
        do {
            try FileManager.default.copyItem(at: url, to: target)
            message = "\"\(target.lastPathComponent)\" importado"
        } catch {
            message = "No se pudo importar el archivo"
        }
        refreshToken += 1
    }

    private func uniqueURL(in dir: String, name: String) -> URL {
        let base = (name as NSString).deletingPathExtension
        let ext = (name as NSString).pathExtension
        var candidate = URL(fileURLWithPath: dir).appendingPathComponent(name)
        var counter = 1
        while FileManager.default.fileExists(atPath: candidate.path) {
            let numbered = ext.isEmpty ? "\(base) (\(counter))" : "\(base) (\(counter)).\(ext)"
            candidate = URL(fileURLWithPath: dir).appendingPathComponent(numbered)
            counter += 1
        }
        return candidate
    }
}
