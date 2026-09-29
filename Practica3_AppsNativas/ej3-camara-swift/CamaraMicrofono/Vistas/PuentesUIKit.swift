import SwiftUI
import UIKit
import AVFoundation
import PhotosUI

// Componentes de UIKit envueltos para SwiftUI.

/// Vista previa en vivo de la cámara (AVCaptureVideoPreviewLayer).
struct VistaPreviaCamara: UIViewRepresentable {
    let sesion: AVCaptureSession

    final class Vista: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var capa: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }

    func makeUIView(context: Context) -> Vista {
        let vista = Vista()
        vista.capa.session = sesion
        vista.capa.videoGravity = .resizeAspectFill
        return vista
    }

    func updateUIView(_ vista: Vista, context: Context) {}
}

/// Selector de la fototeca (PHPickerViewController). Es la fuente alternativa de fotos cuando
/// el dispositivo no tiene cámara, como el simulador de iOS.
struct SelectorFototeca: UIViewControllerRepresentable {
    let alElegir: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuracion = PHPickerConfiguration()
        configuracion.filter = .images
        configuracion.selectionLimit = 1
        let selector = PHPickerViewController(configuration: configuracion)
        selector.delegate = context.coordinator
        return selector
    }

    func updateUIViewController(_ selector: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinador { Coordinador(alElegir: alElegir) }

    final class Coordinador: NSObject, PHPickerViewControllerDelegate {
        let alElegir: (UIImage?) -> Void
        init(alElegir: @escaping (UIImage?) -> Void) { self.alElegir = alElegir }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let proveedor = results.first?.itemProvider, proveedor.canLoadObject(ofClass: UIImage.self) else {
                alElegir(nil)
                return
            }
            proveedor.loadObject(ofClass: UIImage.self) { objeto, _ in
                DispatchQueue.main.async { self.alElegir(objeto as? UIImage) }
            }
        }
    }
}

/// Hoja de compartir del sistema, usada para exportar fotos y grabaciones.
struct HojaCompartir: UIViewControllerRepresentable {
    let elementos: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: elementos, applicationActivities: nil)
    }

    func updateUIViewController(_ controlador: UIActivityViewController, context: Context) {}
}
