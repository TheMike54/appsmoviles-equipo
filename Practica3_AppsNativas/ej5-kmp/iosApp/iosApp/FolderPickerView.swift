import SwiftUI
import SharedLogic

/// Selector de carpeta destino para copiar o mover. Se navega por las subcarpetas de la app
/// (no se sale de la raíz) y se confirma con la carpeta que se está viendo.
struct FolderPickerView: View {
    @EnvironmentObject var model: FileBrowserModel
    @Environment(\.dismiss) private var dismiss
    let request: TransferRequest
    @State private var path = ""

    private var verb: String { request.move ? "Mover" : "Copiar" }

    private var routeText: String {
        "Inicio" + String(path.dropFirst(model.rootPath.count))
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if !path.isEmpty && path != model.rootPath {
                        Button {
                            path = (path as NSString).deletingLastPathComponent
                        } label: {
                            Label("Subir", systemImage: "arrow.up")
                        }
                    }
                    let folders = model.folders(in: path)
                    ForEach(folders, id: \.path) { folder in
                        Button {
                            path = folder.path
                        } label: {
                            Label(folder.name, systemImage: "folder.fill")
                        }
                    }
                    if folders.isEmpty {
                        Text("(sin subcarpetas)")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Label(routeText, systemImage: "folder")
                        .textCase(nil)
                }
            }
            .navigationTitle("\(verb) \"\(request.entry.name)\" a…")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("\(verb) aquí") {
                        model.performTransfer(request.entry, to: path, move: request.move)
                        dismiss()
                    }
                    .disabled(path.isEmpty)
                }
            }
        }
        .onAppear {
            if path.isEmpty { path = model.rootPath }
        }
    }
}
