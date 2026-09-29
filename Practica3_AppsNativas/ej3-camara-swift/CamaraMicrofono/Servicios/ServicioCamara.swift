import AVFoundation
import UIKit
import Observation

/// Cámara con AVFoundation: `AVCaptureSession` + `AVCapturePhotoOutput`.
///
/// El simulador de iOS no tiene cámara: en ese caso `disponible` queda en `false` y la vista
/// ofrece elegir una foto de la fototeca (`PHPickerViewController`).
@Observable
final class ServicioCamara: NSObject {
    enum Estado { case sinConfigurar, sinPermiso, sinCamara, lista }

    private(set) var estado: Estado = .sinConfigurar
    let sesion = AVCaptureSession()
    private let salida = AVCapturePhotoOutput()
    private var alTerminar: ((UIImage?) -> Void)?
    private let cola = DispatchQueue(label: "camara.sesion")

    var disponible: Bool { estado == .lista }

    /// Pide permiso de cámara y configura la sesión si hay un dispositivo.
    func preparar() async {
        guard estado == .sinConfigurar || estado == .sinPermiso else { return }
        var permitido = AVCaptureDevice.authorizationStatus(for: .video) == .authorized
        if AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined {
            permitido = await AVCaptureDevice.requestAccess(for: .video)
        }
        guard permitido else { estado = .sinPermiso; return }
        guard let dispositivo = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let entrada = try? AVCaptureDeviceInput(device: dispositivo) else {
            estado = .sinCamara
            return
        }
        sesion.beginConfiguration()
        sesion.sessionPreset = .photo
        if sesion.canAddInput(entrada) { sesion.addInput(entrada) }
        if sesion.canAddOutput(salida) { sesion.addOutput(salida) }
        sesion.commitConfiguration()
        estado = .lista
        cola.async { self.sesion.startRunning() }
    }

    func detener() {
        cola.async { if self.sesion.isRunning { self.sesion.stopRunning() } }
    }

    /// Toma una foto con el modo de flash indicado.
    func tomarFoto(flash: AVCaptureDevice.FlashMode, alTerminar: @escaping (UIImage?) -> Void) {
        guard disponible else { alTerminar(nil); return }
        self.alTerminar = alTerminar
        let ajustes = AVCapturePhotoSettings()
        if salida.supportedFlashModes.contains(flash) { ajustes.flashMode = flash }
        salida.capturePhoto(with: ajustes, delegate: self)
    }
}

extension ServicioCamara: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        let imagen = photo.fileDataRepresentation().flatMap(UIImage.init(data:))
        DispatchQueue.main.async { self.alTerminar?(imagen) }
    }
}
