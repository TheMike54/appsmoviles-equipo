import AVFoundation
import Observation

/// Grabación con `AVAudioRecorder` y reproducción con `AVAudioPlayer`.
///
/// - Sensibilidad: ajusta la ganancia de entrada (si el hardware lo permite) y el umbral a
///   partir del cual el medidor considera que hay voz.
/// - Temporizador: detiene la grabación sola al llegar al límite elegido.
/// - Si no hay micrófono (por ejemplo, en la Mac virtual del equipo) se informa en pantalla.
@Observable
final class ServicioAudio: NSObject {
    enum Sensibilidad: String, CaseIterable, Identifiable {
        case baja, media, alta
        var id: String { rawValue }
        var nombre: String { rawValue.capitalized }
        /// Ganancia de entrada (0…1) cuando el dispositivo permite ajustarla.
        var ganancia: Float { self == .baja ? 0.3 : self == .media ? 0.6 : 1.0 }
        /// Nivel (dB) a partir del cual se considera que hay sonido.
        var umbral: Float { self == .baja ? -20 : self == .media ? -35 : -50 }
    }

    enum Estado: Equatable { case inactivo, grabando, sinMicrofono, sinPermiso }

    private(set) var estado: Estado = .inactivo
    private(set) var nivel: Float = -160 // dB
    private(set) var transcurrido: TimeInterval = 0
    var sensibilidad: Sensibilidad = .media
    /// 0 = sin límite.
    var limiteSegundos: Int = 0

    private var grabadora: AVAudioRecorder?
    private var urlActual: URL?
    private var temporizador: Timer?
    private var inicio = Date()
    var alTerminar: ((URL, TimeInterval) -> Void)?

    var hayMicrofono: Bool { AVAudioSession.sharedInstance().isInputAvailable }
    /// El medidor supera el umbral de la sensibilidad elegida.
    var detectaSonido: Bool { nivel > sensibilidad.umbral }

    /// Pide permiso de micrófono y revisa que exista una entrada de audio.
    func preparar() async {
        let permitido = await AVAudioApplication.requestRecordPermission()
        guard permitido else { estado = .sinPermiso; return }
        let sesion = AVAudioSession.sharedInstance()
        try? sesion.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try? sesion.setActive(true)
        estado = sesion.isInputAvailable ? .inactivo : .sinMicrofono
    }

    func iniciar() throws {
        guard hayMicrofono else { estado = .sinMicrofono; throw ErrorMedio.sinMicrofono }
        let sesion = AVAudioSession.sharedInstance()
        if sesion.isInputGainSettable { try? sesion.setInputGain(sensibilidad.ganancia) }
        let url = AlmacenMedios.nuevaURLDeAudio()
        let ajustes: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        let grabadora = try AVAudioRecorder(url: url, settings: ajustes)
        grabadora.isMeteringEnabled = true
        guard grabadora.record() else { estado = .sinMicrofono; throw ErrorMedio.sinMicrofono }
        self.grabadora = grabadora
        inicio = Date()
        urlActual = url
        transcurrido = 0
        estado = .grabando
        temporizador = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in self?.actualizar() }
    }

    func detener() {
        guard let grabadora, let urlActual else { return }
        let duracion = grabadora.currentTime
        grabadora.stop()
        temporizador?.invalidate()
        self.grabadora = nil
        self.urlActual = nil
        nivel = -160
        estado = .inactivo
        // Una grabación sin audio (duración cero) no se guarda.
        if duracion < 0.5 {
            try? FileManager.default.removeItem(at: urlActual)
        } else {
            alTerminar?(urlActual, duracion)
        }
    }

    private func actualizar() {
        guard let grabadora else { return }
        grabadora.updateMeters()
        nivel = grabadora.averagePower(forChannel: 0)
        transcurrido = grabadora.currentTime
        // Si después de 1.5 s el tiempo no avanza, no está llegando audio de ninguna entrada.
        if transcurrido == 0 && Date().timeIntervalSince(inicio) > 1.5 {
            detener()
            estado = .sinMicrofono
            return
        }
        if limiteSegundos > 0 && transcurrido >= Double(limiteSegundos) { detener() }
    }
}

/// Reproductor de las grabaciones.
@Observable
final class Reproductor: NSObject, AVAudioPlayerDelegate {
    private(set) var reproduciendo = false
    private(set) var progreso: TimeInterval = 0
    private(set) var duracion: TimeInterval = 0
    private var reproductor: AVAudioPlayer?
    private var temporizador: Timer?

    func cargar(_ url: URL) throws {
        let r = try AVAudioPlayer(contentsOf: url)
        r.delegate = self
        r.prepareToPlay()
        reproductor = r
        duracion = r.duration
        progreso = 0
    }

    func alternar() {
        guard let reproductor else { return }
        if reproductor.isPlaying {
            reproductor.pause()
            reproduciendo = false
            temporizador?.invalidate()
        } else {
            try? AVAudioSession.sharedInstance().setCategory(.playback)
            reproductor.play()
            reproduciendo = true
            temporizador = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                self?.progreso = self?.reproductor?.currentTime ?? 0
            }
        }
    }

    func buscar(_ segundos: TimeInterval) {
        reproductor?.currentTime = segundos
        progreso = segundos
    }

    func detener() {
        reproductor?.stop()
        reproduciendo = false
        temporizador?.invalidate()
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        reproduciendo = false
        progreso = 0
        temporizador?.invalidate()
    }
}
