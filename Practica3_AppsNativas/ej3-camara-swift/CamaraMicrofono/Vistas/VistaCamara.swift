import SwiftUI
import AVFoundation

/// Pestaña Cámara: vista previa, flash, temporizador y filtros.
/// Si no hay cámara (simulador), el disparador abre la fototeca como fuente alternativa.
struct VistaCamara: View {
    @Environment(Ubicacion.self) private var ubicacion
    @State private var camara = ServicioCamara()
    @State private var flash: AVCaptureDevice.FlashMode = .off
    @State private var segundosTemporizador = 0
    @State private var cuentaRegresiva = 0
    @State private var destello = false
    @State private var eligiendoFoto = false
    @State private var capturada: ImagenCapturada?

    struct ImagenCapturada: Identifiable {
        let id = UUID()
        let imagen: UIImage
    }

    var body: some View {
        NavigationStack {
            ZStack {
                fondo
                if cuentaRegresiva > 0 {
                    Text("\(cuentaRegresiva)")
                        .font(.system(size: 96, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 170, height: 170)
                        .background(Circle().fill(.tint))
                        .shadow(radius: 8)
                        .transition(.scale.combined(with: .opacity))
                        .id(cuentaRegresiva)
                        .accessibilityIdentifier("cuentaRegresiva")
                }
                if destello { Color.white.ignoresSafeArea().transition(.opacity) }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .bottom) { controles }
            .navigationTitle("Cámara")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Menu {
                        Picker("Flash", selection: $flash) {
                            Label("Apagado", systemImage: "bolt.slash").tag(AVCaptureDevice.FlashMode.off)
                            Label("Encendido", systemImage: "bolt.fill").tag(AVCaptureDevice.FlashMode.on)
                            Label("Automático", systemImage: "bolt.badge.automatic").tag(AVCaptureDevice.FlashMode.auto)
                        }
                    } label: {
                        Image(systemName: iconoFlash)
                    }
                    .accessibilityLabel("Flash")

                    Menu {
                        Picker("Temporizador", selection: $segundosTemporizador) {
                            Text("Sin temporizador").tag(0)
                            Text("3 segundos").tag(3)
                            Text("10 segundos").tag(10)
                        }
                    } label: {
                        Label(segundosTemporizador == 0 ? "Temporizador" : "\(segundosTemporizador) s",
                              systemImage: segundosTemporizador == 0 ? "timer" : "timer.circle.fill")
                            .labelStyle(.titleAndIcon)
                    }
                    .accessibilityLabel("Temporizador")
                }
            }
            .task {
                await camara.preparar()
                ubicacion.solicitar()
            }
            .onDisappear { camara.detener() }
            .sheet(isPresented: $eligiendoFoto) {
                SelectorFototeca { imagen in
                    eligiendoFoto = false
                    if let imagen { capturada = ImagenCapturada(imagen: imagen) }
                }
                .ignoresSafeArea()
            }
            .sheet(item: $capturada) { captura in
                EditorCaptura(imagen: captura.imagen)
            }
        }
    }

    @ViewBuilder
    private var fondo: some View {
        switch camara.estado {
        case .lista:
            VistaPreviaCamara(sesion: camara.sesion).ignoresSafeArea()
        case .sinConfigurar:
            ProgressView("Preparando cámara…")
        case .sinPermiso:
            ContentUnavailableView {
                Label("Sin permiso de cámara", systemImage: "camera.badge.ellipsis")
            } description: {
                Text(ErrorMedio.permisoDenegado("la cámara").localizedDescription)
            } actions: {
                Button("Elegir de la fototeca") { eligiendoFoto = true }
            }
        case .sinCamara:
            ContentUnavailableView {
                Label("Este dispositivo no tiene cámara", systemImage: "camera.metering.unknown")
            } description: {
                Text("En el simulador de iOS no hay cámara física. El disparador abre la fototeca para elegir una foto; después puedes aplicarle filtros y guardarla.")
            }
        }
    }

    private var controles: some View {
        HStack {
            Button { eligiendoFoto = true } label: {
                Image(systemName: "photo.on.rectangle").font(.title2).frame(width: 56, height: 56)
            }
            .accessibilityLabel("Fototeca")
            Spacer()
            BotonDisparador { disparar() }
            Spacer()
            Label(flash == .off ? "Sin flash" : flash == .on ? "Flash" : "Auto", systemImage: iconoFlash)
                .font(.caption)
                .labelStyle(.iconOnly)
                .frame(width: 56, height: 56)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 12)
        .background(.bar)
    }

    private var iconoFlash: String {
        switch flash {
        case .on: return "bolt.fill"
        case .auto: return "bolt.badge.automatic"
        default: return "bolt.slash"
        }
    }

    /// Cuenta regresiva (si hay temporizador), destello y captura.
    private func disparar() {
        Task { @MainActor in
            if segundosTemporizador > 0 {
                for segundo in stride(from: segundosTemporizador, through: 1, by: -1) {
                    withAnimation(.spring(duration: 0.3)) { cuentaRegresiva = segundo }
                    try? await Task.sleep(for: .seconds(1))
                }
                withAnimation { cuentaRegresiva = 0 }
            }
            if flash != .off {
                withAnimation(.easeIn(duration: 0.05)) { destello = true }
                try? await Task.sleep(for: .milliseconds(150))
                withAnimation(.easeOut(duration: 0.3)) { destello = false }
            }
            if camara.disponible {
                camara.tomarFoto(flash: flash) { imagen in
                    if let imagen { capturada = ImagenCapturada(imagen: imagen) }
                }
            } else {
                eligiendoFoto = true
            }
        }
    }
}

/// Botón circular del disparador, con animación al presionarlo.
struct BotonDisparador: View {
    let accion: () -> Void

    var body: some View {
        Button(action: accion) {
            ZStack {
                Circle().stroke(.tint, lineWidth: 4).frame(width: 76, height: 76)
                Circle().fill(.tint).frame(width: 62, height: 62)
            }
        }
        .buttonStyle(EscalaAlPresionar())
        .accessibilityLabel("Tomar foto")
    }
}

struct EscalaAlPresionar: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}

/// Después de capturar: elegir filtro, álbum y etiquetas, y guardar.
struct EditorCaptura: View {
    let imagen: UIImage
    @Environment(\.dismiss) private var cerrar
    @Environment(Ubicacion.self) private var ubicacion
    @FetchRequest(sortDescriptors: [SortDescriptor(\Album.nombre)]) private var albumes: FetchedResults<Album>

    @State private var filtro: Filtro = .original
    @State private var vistaPrevia: UIImage?
    @State private var miniaturas: [Filtro: UIImage] = [:]
    @State private var album: Album?
    @State private var etiquetas = ""
    @State private var mensajeError: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Image(uiImage: vistaPrevia ?? imagen)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 320)
                        .frame(maxWidth: .infinity)
                        .animation(.easeInOut, value: filtro)
                }
                Section("Filtro") {
                    SelectorFiltros(imagen: imagen, seleccionado: $filtro, miniaturas: $miniaturas)
                }
                Section("Organizar") {
                    Picker("Álbum", selection: $album) {
                        Text("Sin álbum").tag(Album?.none)
                        ForEach(albumes) { Text($0.nombre).tag(Optional($0)) }
                    }
                    TextField("Etiquetas (separadas por comas)", text: $etiquetas)
                }
            }
            .navigationTitle("Nueva foto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Descartar") { cerrar() } }
                ToolbarItem(placement: .confirmationAction) { Button("Guardar") { guardar() } }
            }
            .onChange(of: filtro) { _, nuevo in
                vistaPrevia = nuevo.aplicar(a: imagen.reducida(a: 900))
            }
            .alert("No se pudo guardar", isPresented: Binding(get: { mensajeError != nil }, set: { if !$0 { mensajeError = nil } })) {
                Button("Aceptar", role: .cancel) {}
            } message: { Text(mensajeError ?? "") }
        }
    }

    private func guardar() {
        do {
            let final = filtro.aplicar(a: imagen.reducida(a: 2400))
            let medio = try AlmacenMedios.guardarFoto(final, filtro: filtro, ubicacion: ubicacion.coordenadas, album: album)
            medio.etiquetas = etiquetas
            Persistencia.compartida.guardar()
            cerrar()
        } catch {
            mensajeError = error.localizedDescription
        }
    }
}

/// Tira horizontal con una miniatura por filtro.
struct SelectorFiltros: View {
    let imagen: UIImage
    @Binding var seleccionado: Filtro
    @Binding var miniaturas: [Filtro: UIImage]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Filtro.allCases) { filtro in
                    Button { seleccionado = filtro } label: {
                        VStack(spacing: 4) {
                            Group {
                                if let mini = miniaturas[filtro] {
                                    Image(uiImage: mini).resizable().scaledToFill()
                                } else {
                                    Color.secondary.opacity(0.2)
                                }
                            }
                            .frame(width: 64, height: 64)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(.tint, lineWidth: seleccionado == filtro ? 3 : 0))
                            Text(filtro.nombre).font(.caption2)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("filtro_\(filtro.rawValue)")
                }
            }
            .padding(.vertical, 4)
        }
        .task {
            guard miniaturas.isEmpty else { return }
            let base = imagen.reducida(a: 160)
            for filtro in Filtro.allCases { miniaturas[filtro] = filtro.aplicar(a: base) }
        }
    }
}
