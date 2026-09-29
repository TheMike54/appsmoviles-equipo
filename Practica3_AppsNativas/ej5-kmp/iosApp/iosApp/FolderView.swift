import SwiftUI
import SharedLogic

/// Contenido de una carpeta: lista con íconos por tipo, ruta actual visible, búsqueda en la
/// carpeta, orden (nombre, fecha o tamaño), "deslizar para actualizar" y acciones por
/// archivo (deslizar para eliminar y menú contextual con mantener presionado).
struct FolderView: View {
    @EnvironmentObject var model: FileBrowserModel
    let path: String
    @State private var query = ""

    private var isRoot: Bool { path == model.rootPath }

    private var title: String {
        isRoot ? "Gestor de archivos" : (path as NSString).lastPathComponent
    }

    /// Ruta legible desde la raíz de la app: "Inicio/Fotos/2026".
    private var routeText: String {
        "Inicio" + String(path.dropFirst(model.rootPath.count))
    }

    private var visible: [FileEntry] {
        let all = model.entries(in: path)
        let text = query.trimmingCharacters(in: .whitespaces)
        return text.isEmpty ? all : all.filter { $0.name.localizedCaseInsensitiveContains(text) }
    }

    var body: some View {
        List {
            Section {
                ForEach(visible, id: \.path) { entry in
                    if entry.isDirectory {
                        NavigationLink(value: entry.path) { EntryRow(entry: entry) }
                            .entryActions(entry)
                    } else {
                        NavigationLink { FileDetailView(entry: entry) } label: { EntryRow(entry: entry) }
                            .entryActions(entry)
                    }
                }
            } header: {
                Label(routeText, systemImage: "folder")
                    .textCase(nil)
            }
        }
        .overlay {
            if visible.isEmpty {
                Text(query.isEmpty ? "Esta carpeta está vacía" : "Sin resultados para \"\(query)\"")
                    .foregroundStyle(.secondary)
                    .padding()
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $query, prompt: "Buscar en esta carpeta")
        .refreshable { model.refreshToken += 1 }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                sortMenu
                themeMenu
                addMenu
            }
        }
    }

    // MARK: - Menús de la barra superior

    private var sortMenu: some View {
        Menu {
            sortButton("Nombre", .nombre)
            sortButton("Fecha", .fecha)
            sortButton("Tamaño", .tamano)
            Divider()
            Button {
                model.setAscending(!model.ascending)
            } label: {
                Label(model.ascending ? "Ascendente" : "Descendente",
                      systemImage: model.ascending ? "arrow.up" : "arrow.down")
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
    }

    private func sortButton(_ title: String, _ order: SharedLogic.SortOrder) -> some View {
        Button {
            model.setSort(order)
        } label: {
            if model.sortOrder == order {
                Label(title, systemImage: "checkmark")
            } else {
                Text(title)
            }
        }
    }

    private var themeMenu: some View {
        Menu {
            ForEach(AppTheme.allCases) { theme in
                Button {
                    model.setTheme(theme)
                } label: {
                    if model.theme == theme {
                        Label(theme.label, systemImage: "checkmark")
                    } else {
                        Text(theme.label)
                    }
                }
            }
        } label: {
            Image(systemName: "paintpalette")
        }
    }

    private var addMenu: some View {
        Menu {
            Button { model.askNewFolder() } label: {
                Label("Nueva carpeta", systemImage: "folder.badge.plus")
            }
            Button { model.showImporter = true } label: {
                Label("Importar archivo", systemImage: "square.and.arrow.down")
            }
        } label: {
            Image(systemName: "plus")
        }
    }
}

// MARK: - Fila y acciones (las usan Explorar, Recientes y Favoritos)

/// Ícono según el tipo, nombre, y "tamaño · fecha" (o "Carpeta · fecha").
struct EntryRow: View {
    @EnvironmentObject var model: FileBrowserModel
    let entry: FileEntry

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: entry.iconName)
                .font(.title2)
                .frame(width: 32)
                .foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name)
                    .lineLimit(1)
                Text(entry.detailText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if model.isFavorite(entry) {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundStyle(.yellow)
            }
        }
    }
}

extension View {
    /// Deslizar para eliminar + menú contextual (favorito, copiar, mover, renombrar,
    /// compartir y eliminar) al mantener presionado.
    func entryActions(_ entry: FileEntry) -> some View {
        modifier(EntryActionsModifier(entry: entry))
    }
}

private struct EntryActionsModifier: ViewModifier {
    @EnvironmentObject var model: FileBrowserModel
    let entry: FileEntry

    func body(content: Content) -> some View {
        content
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button(role: .destructive) {
                    model.askDelete(entry)
                } label: {
                    Label("Eliminar", systemImage: "trash")
                }
            }
            .contextMenu {
                Button {
                    model.toggleFavorite(entry)
                } label: {
                    Label(model.isFavorite(entry) ? "Quitar de favoritos" : "Agregar a favoritos",
                          systemImage: model.isFavorite(entry) ? "star.slash" : "star")
                }
                Button {
                    model.transfer = TransferRequest(entry: entry, move: false)
                } label: {
                    Label("Copiar a…", systemImage: "doc.on.doc")
                }
                Button {
                    model.transfer = TransferRequest(entry: entry, move: true)
                } label: {
                    Label("Mover a…", systemImage: "folder")
                }
                Button {
                    model.askRename(entry)
                } label: {
                    Label("Renombrar", systemImage: "pencil")
                }
                if !entry.isDirectory {
                    ShareLink(item: URL(fileURLWithPath: entry.path))
                }
                Button(role: .destructive) {
                    model.askDelete(entry)
                } label: {
                    Label("Eliminar", systemImage: "trash")
                }
            }
    }
}
