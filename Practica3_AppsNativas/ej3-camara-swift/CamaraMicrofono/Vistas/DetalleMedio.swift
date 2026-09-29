import SwiftUI

/// Detalle de una foto (con zoom y edición) o de una grabación (con reproductor),
/// más sus metadatos: fecha, ubicación, filtro, álbum y etiquetas.
struct DetalleMedio: View {
    @ObservedObject var medio: Medio
    @Environment(\.dismiss) private var cerrar
    @FetchRequest(sortDescriptors: [SortDescriptor(\Album.nombre)]) private var albumes: FetchedResults<Album>

    @State private var imagen: UIImage?
    @State private var escala: CGFloat = 1
    @State private var escalaBase: CGFloat = 1
    @State private var editando = false
    @State private var compartiendo = false
    @State private var confirmarEliminar = false
    @State private var reproductor = Reproductor()
    @State private var etiquetas = ""

    var body: some View {
        List {
            Section {
                if medio.esFoto { foto } else { controlesAudio }
            }
            .listRowInsets(EdgeInsets())

            Section("Información") {
                LabeledContent("Fecha", value: medio.fecha.formatted(date: .long, time: .shortened))
                LabeledContent("Ubicación", value: medio.textoUbicacion ?? "Sin ubicación")
                if medio.esFoto {
                    LabeledContent("Filtro", value: medio.filtro.flatMap { Filtro(rawValue: $0)?.nombre } ?? "Original")
                } else {
                    LabeledContent("Duración", value: formatear(medio.duracion))
                }
                LabeledContent("Archivo", value: medio.archivo)
            }

            Section("Organizar") {
                Picker("Álbum", selection: Binding(get: { medio.album }, set: { medio.album = $0; Persistencia.compartida.guardar() })) {
                    Text("Sin álbum").tag(Album?.none)
                    ForEach(albumes) { Text($0.nombre).tag(Optional($0)) }
                }
                TextField("Etiquetas (separadas por comas)", text: $etiquetas)
                    .onSubmit { medio.etiquetas = etiquetas; Persistencia.compartida.guardar() }
                if !medio.listaEtiquetas.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack { ForEach(medio.listaEtiquetas, id: \.self) { Chip(texto: "#\($0)", seleccionado: true) {} } }
                    }
                }
            }
        }
        .navigationTitle(medio.esFoto ? "Foto" : "Grabación")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if medio.esFoto {
                    Button("Editar") { editando = true }
                }
                Button { compartiendo = true } label: { Image(systemName: "square.and.arrow.up") }
                    .accessibilityLabel("Compartir")
                Button(role: .destructive) { confirmarEliminar = true } label: { Image(systemName: "trash") }
                    .accessibilityLabel("Eliminar")
            }
        }
        .confirmationDialog("¿Eliminar este elemento?", isPresented: $confirmarEliminar, titleVisibility: .visible) {
            Button("Eliminar", role: .destructive) {
                reproductor.detener()
                AlmacenMedios.eliminar(medio)
                cerrar()
            }
        }
        .sheet(isPresented: $compartiendo) { HojaCompartir(elementos: [medio.url]) }
        .sheet(isPresented: $editando, onDismiss: cargarImagen) {
            if let imagen { EditorFoto(medio: medio, original: imagen) }
        }
        .onAppear {
            etiquetas = medio.etiquetas
            cargarImagen()
            if !medio.esFoto { try? reproductor.cargar(medio.url) }
        }
        .onDisappear {
            reproductor.detener()
            if etiquetas != medio.etiquetas { medio.etiquetas = etiquetas; Persistencia.compartida.guardar() }
        }
    }

    private var foto: some View {
        Group {
            if let imagen {
                Image(uiImage: imagen)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(escala)
                    .gesture(MagnifyGesture()
                        .onChanged { escala = max(1, min(escalaBase * $0.magnification, 5)) }
                        .onEnded { _ in escalaBase = escala })
                    .onTapGesture(count: 2) { withAnimation { escala = 1; escalaBase = 1 } }
            } else {
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity, minHeight: 280)
        .clipped()
    }

    private var controlesAudio: some View {
        VStack(spacing: 16) {
            Image(systemName: reproductor.reproduciendo ? "waveform" : "waveform.circle")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
                .symbolEffect(.variableColor.iterative, isActive: reproductor.reproduciendo)
            Slider(value: Binding(get: { reproductor.progreso }, set: { reproductor.buscar($0) }),
                   in: 0...max(reproductor.duracion, 0.1))
            HStack {
                Text(formatear(reproductor.progreso))
                Spacer()
                Text(formatear(reproductor.duracion))
            }
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary)
            Button { reproductor.alternar() } label: {
                Image(systemName: reproductor.reproduciendo ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.tint)
            }
            .buttonStyle(EscalaAlPresionar())
            .accessibilityLabel(reproductor.reproduciendo ? "Pausar" : "Reproducir")
        }
        .padding()
    }

    private func cargarImagen() {
        if medio.esFoto { imagen = UIImage(contentsOfFile: medio.url.path) }
    }
}

/// Edición básica de una foto: filtro, girar 90° y recortar al cuadrado.
struct EditorFoto: View {
    @ObservedObject var medio: Medio
    let original: UIImage
    @Environment(\.dismiss) private var cerrar

    @State private var trabajo: UIImage?
    @State private var filtro: Filtro = .original
    @State private var miniaturas: [Filtro: UIImage] = [:]
    @State private var vista: UIImage?

    private var base: UIImage { trabajo ?? original }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(uiImage: vista ?? base)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: .infinity)
                    .animation(.easeInOut, value: vista)
                HStack(spacing: 24) {
                    Button { aplicar { $0.girada90() } } label: { Label("Girar", systemImage: "rotate.left") }
                    Button { aplicar { $0.recortadaCuadrada() } } label: { Label("Recortar", systemImage: "crop") }
                    Button { trabajo = nil; filtro = .original; vista = nil; miniaturas = [:] } label: {
                        Label("Restaurar", systemImage: "arrow.uturn.backward")
                    }
                }
                .buttonStyle(.bordered)
                SelectorFiltros(imagen: base, seleccionado: $filtro, miniaturas: $miniaturas)
                    .id(base)
                    .padding(.horizontal)
            }
            .padding(.vertical)
            .navigationTitle("Editar foto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { cerrar() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        try? AlmacenMedios.sobrescribirFoto(medio, con: filtro.aplicar(a: base), filtro: filtro)
                        cerrar()
                    }
                }
            }
            .onChange(of: filtro) { _, nuevo in vista = nuevo.aplicar(a: base.reducida(a: 900)) }
        }
    }

    private func aplicar(_ transformar: (UIImage) -> UIImage) {
        trabajo = transformar(base)
        miniaturas = [:]
        vista = filtro.aplicar(a: base.reducida(a: 900))
    }
}
