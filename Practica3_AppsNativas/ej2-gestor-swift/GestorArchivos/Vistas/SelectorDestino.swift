import SwiftUI

/// Hoja para elegir la carpeta destino al copiar o mover. Solo muestra carpetas.
struct SelectorDestino: View {
    let titulo: String
    let accion: String
    /// Carpeta que se está moviendo: no se puede mover dentro de sí misma.
    let excluir: URL?
    let alElegir: (URL) -> Void

    @Environment(\.dismiss) private var cerrar
    @State private var ruta: [URL] = []

    var body: some View {
        NavigationStack(path: $ruta) {
            ListaDestinos(url: ServicioArchivos.compartido.documentos, excluir: excluir, accion: accion, alElegir: elegir)
                .navigationTitle(titulo)
                .navigationDestination(for: URL.self) { url in
                    ListaDestinos(url: url, excluir: excluir, accion: accion, alElegir: elegir)
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { cerrar() } }
                }
        }
    }

    private func elegir(_ url: URL) {
        alElegir(url)
        cerrar()
    }
}

private struct ListaDestinos: View {
    let url: URL
    let excluir: URL?
    let accion: String
    let alElegir: (URL) -> Void

    private var carpetas: [ElementoArchivo] {
        ((try? ServicioArchivos.compartido.listar(url)) ?? [])
            .filter { $0.esCarpeta && $0.url.standardizedFileURL != excluir?.standardizedFileURL }
            .sorted { $0.nombre.localizedStandardCompare($1.nombre) == .orderedAscending }
    }

    var body: some View {
        List {
            Section {
                ForEach(carpetas) { carpeta in
                    NavigationLink(value: carpeta.url) {
                        Label(carpeta.nombre, systemImage: "folder.fill")
                    }
                    .accessibilityIdentifier(carpeta.nombre)
                }
            } header: {
                RutaActual(url: url)
            }
        }
        .overlay {
            if carpetas.isEmpty { ContentUnavailableView("Sin subcarpetas", systemImage: "folder") }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(accion) { alElegir(url) }
            }
        }
    }
}
