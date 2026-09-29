import SwiftUI

/// Estructura principal: cuatro pestañas, cada una con su propia pila de navegación.
struct VistaPrincipal: View {
    @Environment(Preferencias.self) private var preferencias

    var body: some View {
        TabView {
            VistaExplorar()
                .tabItem { Label("Explorar", systemImage: "folder") }
            VistaListaGuardada(tipo: .recientes)
                .tabItem { Label("Recientes", systemImage: "clock") }
            VistaListaGuardada(tipo: .favoritos)
                .tabItem { Label("Favoritos", systemImage: "star") }
            VistaAjustes()
                .tabItem { Label("Ajustes", systemImage: "gearshape") }
        }
        .tint(preferencias.tema.color)
    }
}

/// Decide a dónde lleva cada URL al navegar: carpeta o visor de archivo.
struct Destino: View {
    let url: URL

    var body: some View {
        if ServicioArchivos.compartido.esCarpeta(url) {
            VistaCarpeta(url: url)
        } else if ServicioArchivos.compartido.existe(url) {
            VisorArchivo(elemento: ElementoArchivo(url: url))
        } else {
            VistaError(mensaje: ErrorArchivo.noSePudoLeer(url.lastPathComponent).localizedDescription)
        }
    }
}

// MARK: - Explorar

/// Raíces del sandbox (Documents, Inbox, tmp) y ubicaciones externas autorizadas.
/// Al abrir la app se restaura la última carpeta visitada.
struct VistaExplorar: View {
    @Environment(Preferencias.self) private var preferencias
    @Environment(UbicacionesExternas.self) private var externas
    @State private var ruta: [URL] = []
    @State private var restaurada = false
    @State private var eligiendoCarpeta = false
    @State private var mensajeError: String?
    private let servicio = ServicioArchivos.compartido

    var body: some View {
        NavigationStack(path: $ruta) {
            List {
                Section("En este iPhone") {
                    NavigationLink(value: servicio.documentos) {
                        Label("Documentos", systemImage: "doc.on.doc.fill")
                    }
                    if servicio.esCarpeta(servicio.inbox) {
                        NavigationLink(value: servicio.inbox) {
                            Label("Inbox", systemImage: "tray.and.arrow.down.fill")
                        }
                    } else {
                        Label {
                            VStack(alignment: .leading) {
                                Text("Inbox")
                                Text("Aparece cuando otra app te envía un archivo").font(.caption).foregroundStyle(.secondary)
                            }
                        } icon: { Image(systemName: "tray") }
                        .foregroundStyle(.secondary)
                    }
                    NavigationLink(value: servicio.temporal) {
                        Label("Temporales (tmp)", systemImage: "clock.arrow.circlepath")
                    }
                }

                Section {
                    ForEach(externas.ubicaciones) { ubicacion in
                        NavigationLink(value: ubicacion.url) {
                            Label(ubicacion.nombre, systemImage: "externaldrive.connected.to.line.below")
                        }
                        .swipeActions {
                            Button(role: .destructive) { externas.quitar(ubicacion) } label: { Label("Quitar", systemImage: "minus.circle") }
                        }
                    }
                    Button { eligiendoCarpeta = true } label: {
                        Label("Agregar carpeta de Archivos…", systemImage: "plus")
                    }
                } header: {
                    Text("Ubicaciones externas")
                } footer: {
                    Text("Carpetas de la app Archivos o iCloud Drive a las que diste acceso. El permiso se conserva entre sesiones.")
                }
            }
            .navigationTitle("Gestor de Archivos")
            .navigationDestination(for: URL.self) { Destino(url: $0) }
        }
        .sheet(isPresented: $eligiendoCarpeta) {
            SelectorDocumentos(modo: .carpeta) { urls in
                guard let carpeta = urls.first else { return }
                do { try externas.agregar(carpeta) } catch { mensajeError = error.localizedDescription }
            }
            .ignoresSafeArea()
        }
        .alert("No se pudo agregar la carpeta", isPresented: Binding(get: { mensajeError != nil }, set: { if !$0 { mensajeError = nil } })) {
            Button("Aceptar", role: .cancel) {}
        } message: { Text(mensajeError ?? "") }
        .onAppear(perform: restaurarUltimaCarpeta)
    }

    /// Reconstruye la pila de navegación hasta la última carpeta visitada (solo una vez).
    private func restaurarUltimaCarpeta() {
        guard !restaurada else { return }
        restaurada = true
        guard let ultima = preferencias.urlUltimaCarpeta else { return }
        for raiz in [servicio.documentos, servicio.temporal] {
            let base = raiz.standardizedFileURL.pathComponents
            let partes = ultima.standardizedFileURL.pathComponents
            guard partes.starts(with: base) else { continue }
            var actual = raiz
            var pila = [raiz]
            for parte in partes.dropFirst(base.count) {
                actual.appendPathComponent(parte, isDirectory: true)
                pila.append(actual)
            }
            ruta = pila
            return
        }
    }
}

// MARK: - Recientes y favoritos

struct VistaListaGuardada: View {
    enum Tipo { case recientes, favoritos }
    let tipo: Tipo

    @Environment(Preferencias.self) private var preferencias
    @State private var confirmarLimpieza = false

    private var urls: [URL] { tipo == .recientes ? preferencias.urlsRecientes : preferencias.urlsFavoritos }

    var body: some View {
        NavigationStack {
            List {
                ForEach(urls, id: \.self) { url in
                    let elemento = ElementoArchivo(url: url)
                    NavigationLink(value: url) {
                        FilaElemento(elemento: elemento, favorito: tipo == .recientes && preferencias.esFavorito(url))
                    }
                    .accessibilityIdentifier(elemento.nombre)
                    .swipeActions {
                        if tipo == .favoritos {
                            Button(role: .destructive) { preferencias.alternarFavorito(url) } label: {
                                Label("Quitar", systemImage: "star.slash")
                            }
                        }
                    }
                }
            }
            .overlay {
                if urls.isEmpty {
                    ContentUnavailableView(
                        tipo == .recientes ? "Sin archivos recientes" : "Sin favoritos",
                        systemImage: tipo == .recientes ? "clock" : "star",
                        description: Text(tipo == .recientes
                                          ? "Los archivos que abras aparecerán aquí."
                                          : "Mantén presionado un archivo o carpeta y elige «Agregar a favoritos».")
                    )
                }
            }
            .navigationTitle(tipo == .recientes ? "Recientes" : "Favoritos")
            .navigationDestination(for: URL.self) { Destino(url: $0) }
            .toolbar {
                if tipo == .recientes && !urls.isEmpty {
                    Button("Limpiar") { confirmarLimpieza = true }
                }
            }
            .confirmationDialog("¿Borrar el historial de recientes?", isPresented: $confirmarLimpieza, titleVisibility: .visible) {
                Button("Borrar historial", role: .destructive) { preferencias.limpiarRecientes() }
            }
        }
    }
}

// MARK: - Ajustes

struct VistaAjustes: View {
    @Environment(Preferencias.self) private var preferencias
    @State private var tamanoCache: Int64 = 0

    var body: some View {
        @Bindable var preferencias = preferencias
        NavigationStack {
            Form {
                Section {
                    Picker("Tema", selection: $preferencias.tema) {
                        ForEach(Tema.allCases) { tema in
                            HStack {
                                Circle().fill(tema.color).frame(width: 18, height: 18)
                                Text(tema.nombre)
                            }
                            .tag(tema)
                        }
                    }
                    .pickerStyle(.inline)
                } header: {
                    Text("Apariencia")
                } footer: {
                    Text("El modo claro u oscuro sigue la configuración del sistema.")
                }

                Section("Lista de archivos") {
                    Picker("Ordenar por", selection: $preferencias.orden) {
                        ForEach(Orden.allCases) { Text($0.titulo).tag($0) }
                    }
                    Toggle("Orden ascendente", isOn: $preferencias.ascendente)
                    Toggle("Ver como cuadrícula", isOn: $preferencias.enCuadricula)
                }

                Section {
                    LabeledContent("Miniaturas en caché", value: ByteCountFormatter.string(fromByteCount: tamanoCache, countStyle: .file))
                    Button("Limpiar caché de miniaturas", role: .destructive) {
                        Task {
                            await CacheMiniaturas.compartida.limpiar()
                            tamanoCache = await CacheMiniaturas.compartida.tamanoEnDisco()
                        }
                    }
                } header: {
                    Text("Almacenamiento")
                }

                Section("Acerca de") {
                    LabeledContent("Versión", value: "1.0")
                    Text("Los archivos de «Documentos» también aparecen en la app Archivos de iOS, en «En mi iPhone › Gestor de Archivos».")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Ajustes")
            .task { tamanoCache = await CacheMiniaturas.compartida.tamanoEnDisco() }
        }
    }
}
