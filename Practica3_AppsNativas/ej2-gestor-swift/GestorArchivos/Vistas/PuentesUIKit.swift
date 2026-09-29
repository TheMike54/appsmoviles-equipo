import SwiftUI
import UIKit
import UniformTypeIdentifiers

// Componentes de UIKit que SwiftUI no ofrece directamente, envueltos con UIViewControllerRepresentable.

/// Hoja de compartir del sistema (UIActivityViewController): AirDrop, Mensajes, Guardar en Archivos, etc.
struct HojaCompartir: UIViewControllerRepresentable {
    let urls: [URL]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: urls, applicationActivities: nil)
    }

    func updateUIViewController(_ controlador: UIActivityViewController, context: Context) {}
}

/// Selector de documentos del sistema (UIDocumentPickerViewController).
/// - modo `.archivos`: importa (copia) archivos desde la app Archivos o iCloud Drive.
/// - modo `.carpeta`: elige una carpeta externa para abrirla en su lugar (se guarda su marcador).
struct SelectorDocumentos: UIViewControllerRepresentable {
    enum Modo { case archivos, carpeta }

    let modo: Modo
    let alElegir: ([URL]) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let selector: UIDocumentPickerViewController
        switch modo {
        case .archivos:
            selector = UIDocumentPickerViewController(forOpeningContentTypes: [.item], asCopy: false)
            selector.allowsMultipleSelection = true
        case .carpeta:
            selector = UIDocumentPickerViewController(forOpeningContentTypes: [.folder], asCopy: false)
        }
        selector.delegate = context.coordinator
        return selector
    }

    func updateUIViewController(_ selector: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinador { Coordinador(alElegir: alElegir) }

    final class Coordinador: NSObject, UIDocumentPickerDelegate {
        let alElegir: ([URL]) -> Void
        init(alElegir: @escaping ([URL]) -> Void) { self.alElegir = alElegir }
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            alElegir(urls)
        }
    }
}
