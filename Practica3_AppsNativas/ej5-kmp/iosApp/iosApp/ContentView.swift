import SwiftUI
import UniformTypeIdentifiers
import SharedLogic

/// Pantalla raíz: tres pestañas (Explorar, Recientes, Favoritos) y los diálogos comunes.
/// El color del tema (Guinda o Azul) se aplica con .tint y se adapta al modo claro/oscuro.
struct ContentView: View {
    @EnvironmentObject var model: FileBrowserModel
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        TabView(selection: $model.selectedTab) {
            ExploreTab()
                .tabItem { Label("Explorar", systemImage: "folder") }
                .tag(AppTab.explorar)
            RecentsTab()
                .tabItem { Label("Recientes", systemImage: "clock") }
                .tag(AppTab.recientes)
            FavoritesTab()
                .tabItem { Label("Favoritos", systemImage: "star") }
                .tag(AppTab.favoritos)
        }
        .tint(model.theme.primary(scheme))
        .modifier(DialogsModifier())
    }
}

// MARK: - Pestañas

/// Explorar: navegación jerárquica con NavigationStack; cada carpeta es una pantalla.
private struct ExploreTab: View {
    @EnvironmentObject var model: FileBrowserModel

    var body: some View {
        NavigationStack(path: $model.navPath) {
            FolderView(path: model.rootPath)
                .navigationDestination(for: String.self) { path in
                    FolderView(path: path)
                }
        }
    }
}

private struct RecentsTab: View {
    @EnvironmentObject var model: FileBrowserModel

    var body: some View {
        NavigationStack {
            EntryListView(
                entries: model.recents,
                emptyText: "Todavía no has abierto ningún archivo"
            )
            .navigationTitle("Recientes")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !model.recents.isEmpty {
                        Button("Limpiar") { model.clearRecents() }
                    }
                }
            }
        }
    }
}

private struct FavoritesTab: View {
    @EnvironmentObject var model: FileBrowserModel

    var body: some View {
        NavigationStack {
            EntryListView(
                entries: model.favorites,
                emptyText: "Aún no tienes favoritos.\nMantén presionado un archivo para agregarlo."
            )
            .navigationTitle("Favoritos")
        }
    }
}

/// Lista de archivos de Recientes y Favoritos. Una carpeta abre la pestaña Explorar en
/// esa ruta; un archivo abre su visor.
private struct EntryListView: View {
    @EnvironmentObject var model: FileBrowserModel
    let entries: [FileEntry]
    let emptyText: String

    var body: some View {
        List {
            ForEach(entries, id: \.path) { entry in
                if entry.isDirectory {
                    Button { model.goToFolder(entry.path) } label: { EntryRow(entry: entry) }
                        .buttonStyle(.plain)
                        .entryActions(entry)
                } else {
                    NavigationLink { FileDetailView(entry: entry) } label: { EntryRow(entry: entry) }
                        .entryActions(entry)
                }
            }
        }
        .overlay {
            if entries.isEmpty {
                Text(emptyText)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding()
            }
        }
    }
}

// MARK: - Diálogos comunes

/// Nueva carpeta, renombrar, confirmar eliminación, avisos, selector de archivos del
/// sistema (importar) y selector de carpeta destino (copiar/mover). Cada alerta va en su
/// propio fondo para que SwiftUI no descarte ninguna.
private struct DialogsModifier: ViewModifier {
    @EnvironmentObject var model: FileBrowserModel

    func body(content: Content) -> some View {
        content
            .alert("Nueva carpeta", isPresented: $model.showNewFolder) {
                TextField("Nombre", text: $model.inputText)
                Button("Crear") { model.createFolder(named: model.inputText) }
                Button("Cancelar", role: .cancel) {}
            }
            .background(
                Color.clear.alert("Renombrar", isPresented: $model.showRename) {
                    TextField("Nombre", text: $model.inputText)
                    Button("Renombrar") { model.confirmRename() }
                    Button("Cancelar", role: .cancel) {}
                }
            )
            .background(
                Color.clear.alert("Eliminar", isPresented: $model.showDelete) {
                    Button("Eliminar", role: .destructive) { model.confirmDelete() }
                    Button("Cancelar", role: .cancel) {}
                } message: {
                    Text("¿Seguro que quieres eliminar \"\(model.deleteTarget?.name ?? "")\"? Esta acción no se puede deshacer.")
                }
            )
            .background(
                Color.clear.alert("Aviso", isPresented: messageBinding) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(model.message ?? "")
                }
            )
            .fileImporter(isPresented: $model.showImporter, allowedContentTypes: [.item]) { result in
                if case .success(let url) = result {
                    model.importFile(from: url)
                } else if case .failure = result {
                    model.message = "No se pudo importar el archivo"
                }
            }
            .sheet(item: $model.transfer) { request in
                FolderPickerView(request: request)
                    .environmentObject(model)
            }
    }

    private var messageBinding: Binding<Bool> {
        Binding(
            get: { model.message != nil },
            set: { if !$0 { model.message = nil } }
        )
    }
}
