import SwiftUI
import SharedLogic

/// Visor de un archivo: texto (con selección), imágenes ajustadas a la pantalla, o un
/// aviso si todavía no hay visor para ese tipo. Desde aquí también se marca favorito y
/// se comparte con la hoja de compartir del sistema.
struct FileDetailView: View {
    @EnvironmentObject var model: FileBrowserModel
    let entry: FileEntry
    @State private var text: String?

    var body: some View {
        Group {
            if entry.isImage {
                imageContent
            } else if entry.isText {
                textContent
            } else {
                VStack(spacing: 12) {
                    Image(systemName: entry.iconName)
                        .font(.system(size: 56))
                        .foregroundStyle(.tint)
                    Text("Todavía no hay un visor para archivos .\(entry.fileExtension)")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                    Text(entry.detailText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
        }
        .navigationTitle(entry.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    model.toggleFavorite(entry)
                } label: {
                    Image(systemName: model.isFavorite(entry) ? "star.fill" : "star")
                }
                ShareLink(item: URL(fileURLWithPath: entry.path))
            }
        }
        .task {
            // Abrir el archivo lo agrega a Recientes; el texto se lee una sola vez.
            model.registerRecent(entry)
            if entry.isText { text = model.readText(entry) }
        }
    }

    @ViewBuilder
    private var imageContent: some View {
        if let image = UIImage(contentsOfFile: entry.path) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
        } else {
            Text("No se pudo abrir la imagen")
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var textContent: some View {
        if let text {
            ScrollView {
                Text(text)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
        } else {
            ProgressView()
        }
    }
}
