import SwiftUI
import UIKit
import QuickLook

/// Elige el visor adecuado según el tipo de archivo y lo registra en recientes.
struct VisorArchivo: View {
    let elemento: ElementoArchivo
    @Environment(Preferencias.self) private var preferencias
    @State private var compartiendo = false

    var body: some View {
        contenido
            .navigationTitle(elemento.nombre)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        preferencias.alternarFavorito(elemento.url)
                    } label: {
                        Image(systemName: preferencias.esFavorito(elemento.url) ? "star.fill" : "star")
                    }
                    .accessibilityLabel("Favorito")
                    Button { compartiendo = true } label: { Image(systemName: "square.and.arrow.up") }
                        .accessibilityLabel("Compartir")
                }
            }
            .sheet(isPresented: $compartiendo) { HojaCompartir(urls: [elemento.url]) }
            .onAppear { preferencias.registrarReciente(elemento.url) }
    }

    @ViewBuilder
    private var contenido: some View {
        switch elemento.categoria {
        case .texto, .codigo: VisorTexto(elemento: elemento)
        case .imagen: VisorImagen(elemento: elemento)
        default: VisorQuickLook(elemento: elemento)
        }
    }
}

/// PDF, audio, video y demás formatos: se abren con la vista previa nativa de iOS (Quick Look,
/// que usa QLPreviewController) a pantalla completa, igual que en la app Archivos.
struct VisorQuickLook: View {
    let elemento: ElementoArchivo
    @State private var vistaPrevia: URL?
    @State private var yaSeAbrio = false

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: elemento.icono)
                .font(.system(size: 64))
                .foregroundStyle(.tint)
            Text(elemento.nombre).font(.headline)
            Text(elemento.detalle).font(.subheadline).foregroundStyle(.secondary)
            Button {
                vistaPrevia = elemento.url
            } label: {
                Label("Vista previa (Quick Look)", systemImage: "eye")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .quickLookPreview($vistaPrevia)
        .onAppear {
            // Se abre automáticamente la primera vez; al cerrarla queda esta ficha del archivo.
            guard !yaSeAbrio else { return }
            yaSeAbrio = true
            vistaPrevia = elemento.url
        }
    }
}

/// Muestra archivos de texto (.txt, .md, .swift, .json…) con fuente monoespaciada para código.
struct VisorTexto: View {
    let elemento: ElementoArchivo
    @State private var texto: String?
    @State private var error: String?

    var body: some View {
        Group {
            if let texto {
                ScrollView([.vertical, .horizontal]) {
                    Text(texto)
                        .font(elemento.categoria == .codigo ? .system(.body, design: .monospaced) : .body)
                        .textSelection(.enabled)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else if let error {
                VistaError(mensaje: error)
            } else {
                ProgressView()
            }
        }
        .task { cargar() }
    }

    private func cargar() {
        guard let datos = try? Data(contentsOf: elemento.url) else {
            error = ErrorArchivo.noSePudoLeer(elemento.nombre).localizedDescription
            return
        }
        if let utf8 = String(data: datos, encoding: .utf8) {
            texto = utf8
        } else if let latin = String(data: datos, encoding: .isoLatin1) {
            texto = latin
        } else {
            error = ErrorArchivo.formatoNoSoportado(elemento.nombre).localizedDescription
        }
    }
}

/// Visor de imágenes con zoom (pellizco), rotación (dos dedos) y doble toque para ajustar a pantalla.
struct VisorImagen: View {
    let elemento: ElementoArchivo
    @State private var imagen: UIImage?
    @State private var error = false

    @State private var escala: CGFloat = 1
    @State private var escalaBase: CGFloat = 1
    @State private var angulo: Angle = .zero
    @State private var anguloBase: Angle = .zero
    @State private var desplazamiento: CGSize = .zero
    @State private var desplazamientoBase: CGSize = .zero

    var body: some View {
        Group {
            if let imagen {
                Image(uiImage: imagen)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(escala)
                    .rotationEffect(angulo)
                    .offset(desplazamiento)
                    .gesture(
                        MagnifyGesture()
                            .onChanged { escala = max(0.5, min(escalaBase * $0.magnification, 8)) }
                            .onEnded { _ in escalaBase = escala }
                            .simultaneously(with: RotateGesture()
                                .onChanged { angulo = anguloBase + $0.rotation }
                                .onEnded { _ in anguloBase = angulo })
                            .simultaneously(with: DragGesture()
                                .onChanged { valor in
                                    desplazamiento = CGSize(width: desplazamientoBase.width + valor.translation.width,
                                                            height: desplazamientoBase.height + valor.translation.height)
                                }
                                .onEnded { _ in desplazamientoBase = desplazamiento })
                    )
                    .onTapGesture(count: 2) { ajustar() }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
                    .clipped()
            } else if error {
                VistaError(mensaje: ErrorArchivo.formatoNoSoportado(elemento.nombre).localizedDescription)
            } else {
                ProgressView()
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                if imagen != nil {
                Button { withAnimation { angulo -= .degrees(90); anguloBase = angulo } } label: {
                    Label("Girar", systemImage: "rotate.left")
                }
                Spacer()
                Text("\(Int(escala * 100)) %").monospacedDigit().foregroundStyle(.secondary)
                Spacer()
                Button { ajustar() } label: { Label("Ajustar", systemImage: "arrow.up.left.and.down.right.magnifyingglass") }
                }
            }
        }
        .task {
            if let cargada = UIImage(contentsOfFile: elemento.url.path) { imagen = cargada } else { error = true }
        }
    }

    /// Regresa la imagen a su tamaño y posición originales (ajustada a pantalla).
    private func ajustar() {
        withAnimation(.easeInOut(duration: 0.2)) {
            escala = 1; escalaBase = 1
            angulo = .zero; anguloBase = .zero
            desplazamiento = .zero; desplazamientoBase = .zero
        }
    }
}

/// Mensaje de error a pantalla completa para archivos que no se pueden abrir.
struct VistaError: View {
    let mensaje: String

    var body: some View {
        ContentUnavailableView {
            Label("No se puede abrir", systemImage: "exclamationmark.triangle")
        } description: {
            Text(mensaje)
        }
    }
}
