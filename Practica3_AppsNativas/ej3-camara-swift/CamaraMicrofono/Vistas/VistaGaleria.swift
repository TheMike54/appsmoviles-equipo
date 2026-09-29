import SwiftUI
import UniformTypeIdentifiers

/// Pestaña Galería: fotos y grabaciones guardadas, filtradas por tipo y por álbum.
/// Permite crear álbumes, importar desde la app Archivos y exportar con la hoja de compartir.
struct VistaGaleria: View {
    enum TipoFiltro: String, CaseIterable, Identifiable {
        case todo = "Todo", fotos = "Fotos", audios = "Audios"
        var id: String { rawValue }
    }

    @Environment(\.managedObjectContext) private var contexto
    @FetchRequest(sortDescriptors: [SortDescriptor(\Medio.fecha, order: .reverse)]) private var medios: FetchedResults<Medio>
    @FetchRequest(sortDescriptors: [SortDescriptor(\Album.nombre)]) private var albumes: FetchedResults<Album>

    @State private var tipo: TipoFiltro = .todo
    @State private var albumElegido: Album?
    @State private var creandoAlbum = false
    @State private var nombreAlbum = ""
    @State private var importando = false
    @State private var exportando = false
    @State private var porEliminar: Medio?
    @State private var mensajeError: String?

    private var visibles: [Medio] {
        medios.filter { medio in
            (tipo == .todo || (tipo == .fotos) == medio.esFoto) && (albumElegido == nil || medio.album == albumElegido)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Picker("Tipo", selection: $tipo) {
                        ForEach(TipoFiltro.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    chipsDeAlbumes

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 6)], spacing: 6) {
                        ForEach(visibles) { medio in
                            NavigationLink(value: medio) {
                                CeldaMedio(medio: medio)
                            }
                            .accessibilityIdentifier("medio_\(medio.archivo)")
                            .contextMenu { menuContextual(medio) }
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, 6)
                    .animation(.easeInOut, value: visibles.map(\.id))
                }
                .padding(.top, 8)
            }
            .overlay {
                if visibles.isEmpty {
                    ContentUnavailableView("Sin contenido", systemImage: "photo.on.rectangle.angled",
                                           description: Text("Toma fotos, graba audios o importa archivos."))
                }
            }
            .navigationTitle("Galería")
            .navigationDestination(for: Medio.self) { DetalleMedio(medio: $0) }
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button { exportando = true } label: { Image(systemName: "square.and.arrow.up") }
                        .accessibilityLabel("Exportar")
                        .disabled(visibles.isEmpty)
                    Menu {
                        Button { nombreAlbum = ""; creandoAlbum = true } label: { Label("Nuevo álbum", systemImage: "rectangle.stack.badge.plus") }
                        Button { importando = true } label: { Label("Importar de Archivos", systemImage: "square.and.arrow.down") }
                    } label: { Image(systemName: "plus.circle.fill") }
                    .accessibilityLabel("Agregar")
                }
            }
            .alert("Nuevo álbum", isPresented: $creandoAlbum) {
                TextField("Nombre", text: $nombreAlbum)
                Button("Cancelar", role: .cancel) {}
                Button("Crear") { crearAlbum() }
            }
            .confirmationDialog("¿Eliminar este elemento?", isPresented: Binding(get: { porEliminar != nil }, set: { if !$0 { porEliminar = nil } }),
                                titleVisibility: .visible, presenting: porEliminar) { medio in
                Button("Eliminar", role: .destructive) { withAnimation { AlmacenMedios.eliminar(medio) } }
            }
            .fileImporter(isPresented: $importando, allowedContentTypes: [.image, .audio], allowsMultipleSelection: true) { resultado in
                do {
                    for url in try resultado.get() { try AlmacenMedios.importar(url) }
                } catch {
                    mensajeError = error.localizedDescription
                }
            }
            .sheet(isPresented: $exportando) { HojaCompartir(elementos: visibles.map(\.url)) }
            .alert("No se pudo importar", isPresented: Binding(get: { mensajeError != nil }, set: { if !$0 { mensajeError = nil } })) {
                Button("Aceptar", role: .cancel) {}
            } message: { Text(mensajeError ?? "") }
        }
    }

    private var chipsDeAlbumes: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Chip(texto: "Todos los álbumes", seleccionado: albumElegido == nil) { albumElegido = nil }
                ForEach(albumes) { album in
                    Chip(texto: "\(album.nombre) (\(album.medios.count))", seleccionado: albumElegido == album) {
                        albumElegido = album
                    }
                    .contextMenu {
                        Button(role: .destructive) { contexto.delete(album); Persistencia.compartida.guardar() } label: {
                            Label("Eliminar álbum", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private func menuContextual(_ medio: Medio) -> some View {
        Menu {
            Button("Sin álbum") { medio.album = nil; Persistencia.compartida.guardar() }
            ForEach(albumes) { album in
                Button(album.nombre) { medio.album = album; Persistencia.compartida.guardar() }
            }
        } label: { Label("Mover a álbum", systemImage: "rectangle.stack") }
        Button(role: .destructive) { porEliminar = medio } label: { Label("Eliminar", systemImage: "trash") }
    }

    private func crearAlbum() {
        let nombre = nombreAlbum.trimmingCharacters(in: .whitespaces)
        guard !nombre.isEmpty else { return }
        let album = Album(context: contexto)
        album.id = UUID()
        album.nombre = nombre
        album.fecha = Date()
        Persistencia.compartida.guardar()
    }
}

struct Chip: View {
    let texto: String
    let seleccionado: Bool
    let accion: () -> Void

    var body: some View {
        Button(action: accion) {
            Text(texto)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(seleccionado ? AnyShapeStyle(.tint) : AnyShapeStyle(Color.secondary.opacity(0.15)), in: Capsule())
                .foregroundStyle(seleccionado ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

/// Celda de la galería: miniatura de la foto o tarjeta de audio con su duración.
struct CeldaMedio: View {
    @ObservedObject var medio: Medio
    @State private var miniatura: UIImage?

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if medio.esFoto {
                Color.secondary.opacity(0.15)
                    .overlay { if let miniatura { Image(uiImage: miniatura).resizable().scaledToFill() } }
            } else {
                LinearGradient(colors: [Color.accentColor.opacity(0.8), Color.accentColor.opacity(0.4)], startPoint: .top, endPoint: .bottom)
                    .overlay(Image(systemName: "waveform").font(.largeTitle).foregroundStyle(.white))
                Text(formatear(medio.duracion)).font(.caption.monospacedDigit()).foregroundStyle(.white).padding(6)
            }
            if medio.album != nil {
                Image(systemName: "rectangle.stack.fill").font(.caption2).foregroundStyle(.white).padding(6)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            }
        }
        .frame(height: 110)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .contentShape(Rectangle())
        .task(id: medio.fecha) {
            if medio.esFoto { miniatura = AlmacenMedios.miniatura(de: medio) }
        }
    }
}

/// Fila de audio para las listas.
struct FilaAudio: View {
    @ObservedObject var medio: Medio

    var body: some View {
        HStack {
            Image(systemName: "waveform.circle.fill").font(.title2).foregroundStyle(.tint)
            VStack(alignment: .leading) {
                Text(medio.url.deletingPathExtension().lastPathComponent).lineLimit(1)
                Text(medio.fecha.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(formatear(medio.duracion)).font(.caption.monospacedDigit()).foregroundStyle(.secondary)
        }
    }
}
