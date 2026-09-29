import SwiftUI

/// Contenido de una carpeta: lista o cuadrícula, búsqueda, orden, gestos y todas las
/// operaciones de gestión (crear carpeta, importar, renombrar, copiar, mover, compartir, eliminar).
struct VistaCarpeta: View {
    let url: URL

    @Environment(Preferencias.self) private var preferencias
    @Environment(UbicacionesExternas.self) private var externas
    private let servicio = ServicioArchivos.compartido

    @State private var elementos: [ElementoArchivo] = []
    @State private var busqueda = ""
    @State private var mensajeError: String?

    // Diálogos y hojas
    @State private var creandoCarpeta = false
    @State private var nombreNuevo = ""
    @State private var renombrando: ElementoArchivo?
    @State private var porEliminar: ElementoArchivo?
    @State private var operacionDestino: OperacionDestino?
    @State private var compartiendo: ElementoArchivo?
    @State private var importando = false

    struct OperacionDestino: Identifiable {
        enum Tipo { case copiar, mover }
        let tipo: Tipo
        let elemento: ElementoArchivo
        var id: URL { elemento.url }
    }

    private var visibles: [ElementoArchivo] {
        let filtrados = busqueda.isEmpty
            ? elementos
            : elementos.filter { $0.nombre.localizedCaseInsensitiveContains(busqueda) }
        return preferencias.orden.ordenar(filtrados, ascendente: preferencias.ascendente)
    }

    var body: some View {
        Group {
            if preferencias.enCuadricula { cuadricula } else { lista }
        }
        .overlay { estadoVacio }
        .navigationTitle(url.lastPathComponent)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $busqueda, prompt: "Buscar en esta carpeta")
        .refreshable { cargar() }
        .toolbar { barraHerramientas }
        .onAppear {
            cargar()
            if servicio.estaEnSandbox(url) { preferencias.recordarCarpeta(url) }
        }
        // Crear carpeta
        .alert("Nueva carpeta", isPresented: $creandoCarpeta) {
            TextField("Nombre", text: $nombreNuevo)
            Button("Cancelar", role: .cancel) {}
            Button("Crear") { ejecutar { _ = try servicio.crearCarpeta(nombre: nombreNuevo, en: url) } }
        }
        // Renombrar
        .alert("Renombrar", isPresented: Binding(get: { renombrando != nil }, set: { if !$0 { renombrando = nil } }), presenting: renombrando) { elemento in
            TextField("Nombre", text: $nombreNuevo)
            Button("Cancelar", role: .cancel) {}
            Button("Guardar") {
                ejecutar {
                    let nueva = try servicio.renombrar(elemento.url, a: nombreNuevo)
                    preferencias.actualizarRuta(de: elemento.url, a: nueva)
                }
            }
        }
        // Eliminar con confirmación
        .confirmationDialog("¿Eliminar «\(porEliminar?.nombre ?? "")»?",
                            isPresented: Binding(get: { porEliminar != nil }, set: { if !$0 { porEliminar = nil } }),
                            titleVisibility: .visible, presenting: porEliminar) { elemento in
            Button("Eliminar", role: .destructive) {
                ejecutar {
                    try servicio.eliminar(elemento.url)
                    preferencias.actualizarRuta(de: elemento.url, a: nil)
                }
            }
        } message: { elemento in
            Text(elemento.esCarpeta ? "Se borrará la carpeta y todo su contenido. No se puede deshacer." : "Esta acción no se puede deshacer.")
        }
        // Errores
        .alert("No se pudo completar", isPresented: Binding(get: { mensajeError != nil }, set: { if !$0 { mensajeError = nil } })) {
            Button("Aceptar", role: .cancel) {}
        } message: { Text(mensajeError ?? "") }
        .sheet(item: $operacionDestino) { operacion in
            SelectorDestino(titulo: operacion.tipo == .copiar ? "Copiar a…" : "Mover a…",
                            accion: operacion.tipo == .copiar ? "Copiar aquí" : "Mover aquí",
                            excluir: operacion.elemento.esCarpeta ? operacion.elemento.url : nil) { destino in
                ejecutar {
                    if operacion.tipo == .copiar {
                        _ = try servicio.copiar(operacion.elemento.url, a: destino)
                    } else {
                        let nueva = try servicio.mover(operacion.elemento.url, a: destino)
                        preferencias.actualizarRuta(de: operacion.elemento.url, a: nueva)
                    }
                }
            }
        }
        .sheet(item: $compartiendo) { elemento in HojaCompartir(urls: [elemento.url]) }
        .sheet(isPresented: $importando) {
            SelectorDocumentos(modo: .archivos) { urls in
                ejecutar { for externo in urls { _ = try servicio.importar(externo, a: url) } }
            }
            .ignoresSafeArea()
        }
    }

    // MARK: Lista y cuadrícula

    private var lista: some View {
        List {
            Section {
                ForEach(visibles) { elemento in
                    NavigationLink(value: elemento.url) {
                        FilaElemento(elemento: elemento, favorito: preferencias.esFavorito(elemento.url))
                    }
                    .accessibilityIdentifier(elemento.nombre)
                    .swipeActions(edge: .trailing) {
                        Button { porEliminar = elemento } label: { Label("Eliminar", systemImage: "trash") }
                            .tint(.red)
                        Button { preferencias.alternarFavorito(elemento.url) } label: {
                            Label("Favorito", systemImage: "star")
                        }
                        .tint(.orange)
                    }
                    .contextMenu { menuContextual(elemento) }
                }
            } header: {
                RutaActual(url: url)
            }
        }
        .listStyle(.insetGrouped)
    }

    private var cuadricula: some View {
        ScrollView {
            RutaActual(url: url).padding(.horizontal).frame(maxWidth: .infinity, alignment: .leading)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 16)], spacing: 16) {
                ForEach(visibles) { elemento in
                    NavigationLink(value: elemento.url) {
                        CeldaElemento(elemento: elemento, favorito: preferencias.esFavorito(elemento.url))
                    }
                    .accessibilityIdentifier(elemento.nombre)
                    .buttonStyle(.plain)
                    .contextMenu { menuContextual(elemento) }
                }
            }
            .padding()
        }
    }

    @ViewBuilder
    private var estadoVacio: some View {
        if visibles.isEmpty {
            if busqueda.isEmpty {
                ContentUnavailableView("Carpeta vacía", systemImage: "folder",
                                       description: Text("Usa el botón + para crear una carpeta o importar archivos."))
            } else {
                ContentUnavailableView.search(text: busqueda)
            }
        }
    }

    // MARK: Menú contextual (mantener presionado)

    @ViewBuilder
    private func menuContextual(_ elemento: ElementoArchivo) -> some View {
        Button { nombreNuevo = elemento.nombre; renombrando = elemento } label: { Label("Renombrar", systemImage: "pencil") }
        Button { operacionDestino = .init(tipo: .copiar, elemento: elemento) } label: { Label("Copiar a…", systemImage: "doc.on.doc") }
        Button { operacionDestino = .init(tipo: .mover, elemento: elemento) } label: { Label("Mover a…", systemImage: "folder") }
        Button { preferencias.alternarFavorito(elemento.url) } label: {
            preferencias.esFavorito(elemento.url)
                ? Label("Quitar de favoritos", systemImage: "star.slash")
                : Label("Agregar a favoritos", systemImage: "star")
        }
        Button { compartiendo = elemento } label: { Label("Compartir", systemImage: "square.and.arrow.up") }
        Divider()
        Button(role: .destructive) { porEliminar = elemento } label: { Label("Eliminar", systemImage: "trash") }
    }

    // MARK: Barra de herramientas

    @ToolbarContentBuilder
    private var barraHerramientas: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Menu {
                Picker("Ordenar por", selection: Bindable(preferencias).orden) {
                    ForEach(Orden.allCases) { Text($0.titulo).tag($0) }
                }
                Toggle("Ascendente", isOn: Bindable(preferencias).ascendente)
                Divider()
                Toggle("Ver como cuadrícula", isOn: Bindable(preferencias).enCuadricula)
            } label: {
                Image(systemName: "arrow.up.arrow.down.circle")
            }
            .accessibilityLabel("Ordenar y vista")

            Menu {
                Button { nombreNuevo = ""; creandoCarpeta = true } label: { Label("Nueva carpeta", systemImage: "folder.badge.plus") }
                Button { importando = true } label: { Label("Importar archivos", systemImage: "square.and.arrow.down") }
            } label: {
                Image(systemName: "plus.circle.fill")
            }
            .accessibilityLabel("Agregar")
        }
    }

    // MARK: Acciones

    private func cargar() {
        if externas.contiene(url) { _ = externas.abrirAcceso(url) }
        do {
            elementos = try servicio.listar(url)
        } catch {
            elementos = []
            mensajeError = error.localizedDescription
        }
    }

    /// Ejecuta una operación, recarga la carpeta y muestra el error si algo falla.
    private func ejecutar(_ operacion: () throws -> Void) {
        do { try operacion() } catch { mensajeError = error.localizedDescription }
        cargar()
    }
}

/// Encabezado con la ruta de la carpeta actual, relativa al contenedor de la app.
struct RutaActual: View {
    let url: URL

    var body: some View {
        let contenedor = ServicioArchivos.compartido.contenedor.standardizedFileURL.pathComponents
        let partes = url.standardizedFileURL.pathComponents
        let relativas = partes.starts(with: contenedor) ? Array(partes.dropFirst(contenedor.count)) : Array(partes.suffix(3))
        Label(relativas.joined(separator: " › "), systemImage: "folder")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .lineLimit(2)
            .textCase(nil)
    }
}

/// Fila de la lista: miniatura o ícono, nombre y detalle.
struct FilaElemento: View {
    let elemento: ElementoArchivo
    let favorito: Bool

    var body: some View {
        HStack(spacing: 12) {
            Miniatura(elemento: elemento, lado: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(elemento.nombre).lineLimit(1)
                Text(elemento.detalle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if favorito { Image(systemName: "star.fill").foregroundStyle(.orange).font(.caption) }
        }
    }
}

/// Celda de la cuadrícula.
struct CeldaElemento: View {
    let elemento: ElementoArchivo
    let favorito: Bool

    var body: some View {
        VStack(spacing: 6) {
            Miniatura(elemento: elemento, lado: 80)
                .overlay(alignment: .topTrailing) {
                    if favorito { Image(systemName: "star.fill").foregroundStyle(.orange).font(.caption).padding(4) }
                }
            Text(elemento.nombre).font(.caption).lineLimit(2).multilineTextAlignment(.center)
        }
    }
}

/// Miniatura de una imagen (desde la caché) o el ícono de su tipo de archivo.
struct Miniatura: View {
    let elemento: ElementoArchivo
    let lado: CGFloat
    @State private var imagen: UIImage?

    var body: some View {
        Group {
            if let imagen {
                Image(uiImage: imagen).resizable().scaledToFill()
            } else {
                Image(systemName: elemento.icono)
                    .font(.system(size: lado * 0.45))
                    .foregroundStyle(elemento.esCarpeta ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
            }
        }
        .frame(width: lado, height: lado)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: lado * 0.18))
        .task(id: elemento) {
            guard elemento.categoria == .imagen else { return }
            imagen = await CacheMiniaturas.compartida.miniatura(de: elemento, lado: lado)
        }
    }
}
