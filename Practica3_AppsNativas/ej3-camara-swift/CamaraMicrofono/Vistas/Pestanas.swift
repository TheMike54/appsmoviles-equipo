import SwiftUI
import CoreData

/// Tema elegido por el usuario (se guarda en UserDefaults con @AppStorage).
struct VistaPrincipal: View {
    @AppStorage("tema") private var tema: Tema = .guinda

    var body: some View {
        TabView {
            VistaCamara()
                .tabItem { Label("Cámara", systemImage: "camera") }
            VistaGrabadora()
                .tabItem { Label("Grabadora", systemImage: "mic") }
            VistaGaleria()
                .tabItem { Label("Galería", systemImage: "photo.on.rectangle") }
            VistaAjustes()
                .tabItem { Label("Ajustes", systemImage: "gearshape") }
        }
        .tint(tema.color)
    }
}

struct VistaAjustes: View {
    @AppStorage("tema") private var tema: Tema = .guinda
    @FetchRequest(sortDescriptors: []) private var medios: FetchedResults<Medio>
    @FetchRequest(sortDescriptors: []) private var albumes: FetchedResults<Album>

    private var espacio: Int64 {
        medios.reduce(0) { $0 + Int64((try? $1.url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0) }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Tema", selection: $tema) {
                        ForEach(Tema.allCases) { opcion in
                            HStack {
                                Circle().fill(opcion.color).frame(width: 18, height: 18)
                                Text(opcion.nombre)
                            }
                            .tag(opcion)
                        }
                    }
                    .pickerStyle(.inline)
                } header: {
                    Text("Apariencia")
                } footer: {
                    Text("El modo claro u oscuro sigue la configuración del sistema.")
                }

                Section("Almacenamiento") {
                    LabeledContent("Fotos", value: "\(medios.filter(\.esFoto).count)")
                    LabeledContent("Grabaciones", value: "\(medios.filter { !$0.esFoto }.count)")
                    LabeledContent("Álbumes", value: "\(albumes.count)")
                    LabeledContent("Espacio usado", value: ByteCountFormatter.string(fromByteCount: espacio, countStyle: .file))
                }

                Section("Acerca de") {
                    Text("Todo se guarda en el dispositivo y funciona sin conexión. Las fotos y grabaciones también aparecen en la app Archivos, en «En mi iPhone › Cámara y Micrófono».")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Ajustes")
        }
    }
}
