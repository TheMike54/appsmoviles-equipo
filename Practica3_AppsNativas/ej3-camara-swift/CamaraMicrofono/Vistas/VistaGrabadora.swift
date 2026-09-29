import SwiftUI

/// Pestaña Grabadora: sensibilidad, temporizador, medidor de nivel y botón de grabar.
struct VistaGrabadora: View {
    @Environment(Ubicacion.self) private var ubicacion
    @State private var audio = ServicioAudio()
    @State private var mensajeError: String?
    @FetchRequest(sortDescriptors: [SortDescriptor(\Medio.fecha, order: .reverse)],
                  predicate: NSPredicate(format: "tipo == 'audio'")) private var grabaciones: FetchedResults<Medio>

    private let limites = [0, 15, 30, 60]

    var body: some View {
        @Bindable var audio = audio
        NavigationStack {
            List {
                if audio.estado == .sinMicrofono || audio.estado == .sinPermiso {
                    Section {
                        Label {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(audio.estado == .sinPermiso ? "Sin permiso de micrófono" : "No hay micrófono disponible")
                                    .font(.headline)
                                Text(audio.estado == .sinPermiso
                                     ? ErrorMedio.permisoDenegado("el micrófono").localizedDescription
                                     : "Este dispositivo no tiene una entrada de audio (por ejemplo, el simulador en un equipo sin micrófono). Puedes importar audios desde la Galería.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "mic.slash.fill").foregroundStyle(.orange)
                        }
                    }
                }

                Section {
                    VStack(spacing: 16) {
                        Text(formatear(audio.transcurrido))
                            .font(.system(size: 52, weight: .light, design: .monospaced))
                            .contentTransition(.numericText())
                        MedidorNivel(nivel: audio.nivel, umbral: audio.sensibilidad.umbral)
                            .frame(height: 14)
                        Button {
                            alternar()
                        } label: {
                            ZStack {
                                Circle().stroke(.tint, lineWidth: 4).frame(width: 84, height: 84)
                                RoundedRectangle(cornerRadius: audio.estado == .grabando ? 8 : 34)
                                    .fill(Color.red)
                                    .frame(width: audio.estado == .grabando ? 36 : 68, height: audio.estado == .grabando ? 36 : 68)
                                    .animation(.spring(duration: 0.3), value: audio.estado)
                            }
                        }
                        .buttonStyle(EscalaAlPresionar())
                        .disabled(audio.estado == .sinMicrofono || audio.estado == .sinPermiso)
                        .opacity(audio.estado == .sinMicrofono || audio.estado == .sinPermiso ? 0.4 : 1)
                        .accessibilityLabel(audio.estado == .grabando ? "Detener grabación" : "Grabar")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }

                Section("Opciones de grabación") {
                    Picker("Sensibilidad", selection: $audio.sensibilidad) {
                        ForEach(ServicioAudio.Sensibilidad.allCases) { Text($0.nombre).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    Picker("Temporizador", selection: $audio.limiteSegundos) {
                        ForEach(limites, id: \.self) { Text($0 == 0 ? "Sin límite" : "\($0) s").tag($0) }
                    }
                }

                Section("Grabaciones recientes") {
                    if grabaciones.isEmpty {
                        Text("Aún no hay grabaciones.").foregroundStyle(.secondary)
                    }
                    ForEach(grabaciones.prefix(5)) { medio in
                        NavigationLink(value: medio) { FilaAudio(medio: medio) }
                    }
                }
            }
            .navigationTitle("Grabadora")
            .navigationDestination(for: Medio.self) { DetalleMedio(medio: $0) }
            .task {
                await audio.preparar()
                audio.alTerminar = { url, duracion in
                    AlmacenMedios.registrarAudio(nombre: url.lastPathComponent, duracion: duracion, ubicacion: ubicacion.coordenadas)
                }
            }
            .alert("No se pudo grabar", isPresented: Binding(get: { mensajeError != nil }, set: { if !$0 { mensajeError = nil } })) {
                Button("Aceptar", role: .cancel) {}
            } message: { Text(mensajeError ?? "") }
        }
    }

    private func alternar() {
        if audio.estado == .grabando {
            audio.detener()
        } else {
            do { try audio.iniciar() } catch { mensajeError = error.localizedDescription }
        }
    }
}

/// Barra de nivel de entrada; la marca vertical es el umbral de la sensibilidad elegida.
struct MedidorNivel: View {
    let nivel: Float
    let umbral: Float

    private func proporcion(_ db: Float) -> CGFloat { CGFloat(max(0, min(1, (db + 60) / 60))) }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.secondary.opacity(0.2))
                Capsule()
                    .fill(nivel > umbral ? Color.green : Color.secondary)
                    .frame(width: geo.size.width * proporcion(nivel))
                    .animation(.linear(duration: 0.1), value: nivel)
                Rectangle().fill(.tint).frame(width: 2).offset(x: geo.size.width * proporcion(umbral))
            }
        }
        .accessibilityLabel("Nivel de entrada")
    }
}

func formatear(_ segundos: TimeInterval) -> String {
    let total = Int(segundos)
    return String(format: "%02d:%02d", total / 60, total % 60)
}
