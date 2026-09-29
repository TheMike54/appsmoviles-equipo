import XCTest

/// Recorrido guiado para tomar capturas "código + app": en cada paso deja la app en una
/// pantalla y pide (con un archivo de señal) que Xcode muestre el código correspondiente;
/// luego espera unos segundos para tomar la captura.
///
/// Solo corre si se define la variable `TEST_RUNNER_RECORRIDO=1` al ejecutar `xcodebuild test`;
/// en una ejecución normal de las pruebas se omite.
final class RecorridoParaCapturas: XCTestCase {
    private var app: XCUIApplication!
    private let trampolin = XCUIApplication(bundleIdentifier: "com.apple.springboard")
    private let pausa: UInt32 = 10

    override func setUpWithError() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["RECORRIDO"] == "1", "Recorrido manual de capturas")
        continueAfterFailure = true
        XCUIDevice.shared.orientation = .portrait
        app = XCUIApplication()
        app.launchArguments = ["-reiniciarDemo"]
        app.launch()
    }

    func testRecorrido() {
        // Permiso de cámara (Info.plist: NSCameraUsageDescription)
        if trampolin.alerts.firstMatch.waitForExistence(timeout: 10) {
            paso(1, "Info.plist", "NSCameraUsageDescription")
        }
        aceptarPermisos()

        toca(el("Este dispositivo no tiene cámara"), tocar: false)
        paso(2, "Servicios/ServicioCamara.swift", "func preparar")

        toca(app.buttons["Flash"])
        paso(3, "Vistas/VistaCamara.swift", "Picker(\"Flash\"")
        toca(el("Encendido"))
        toca(app.buttons["Temporizador"])
        toca(el("3 segundos"))

        toca(app.buttons["Tomar foto"])
        if el("cuentaRegresiva").waitForExistence(timeout: 3) {
            senal(4, "Vistas/VistaCamara.swift", "private func disparar")
        }
        sleep(6)
        paso(5, "Vistas/PuentesUIKit.swift", "struct SelectorFototeca")
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.17, dy: 0.41)).tap()

        _ = app.navigationBars["Nueva foto"].waitForExistence(timeout: 30)
        sleep(2)
        toca(el("filtro_sepia"))
        sleep(2)
        paso(6, "Servicios/Filtros.swift", "func aplicar")
        toca(app.buttons["Guardar"])
        sleep(2)

        toca(app.tabBars.buttons["Galería"])
        sleep(3)
        paso(7, "Vistas/VistaGaleria.swift", "struct VistaGaleria")

        let foto = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'medio_Fotos/'")).firstMatch
        toca(foto)
        sleep(2)
        paso(8, "Datos/Persistencia.swift", "static let modelo")

        toca(app.buttons["Editar"])
        _ = app.navigationBars["Editar foto"].waitForExistence(timeout: 10)
        toca(el("filtro_noir"))
        toca(el("Girar"))
        sleep(2)
        paso(9, "Vistas/DetalleMedio.swift", "struct EditorFoto")
        toca(app.buttons["Guardar"])
        sleep(2)
        regresar()

        let audio = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'medio_Audios/'")).firstMatch
        toca(audio)
        toca(app.buttons["Reproducir"])
        sleep(1)
        paso(10, "Servicios/ServicioAudio.swift", "final class Reproductor")
        if app.buttons["Pausar"].exists { app.buttons["Pausar"].tap() }
        regresar()

        toca(app.buttons["Agregar"])
        toca(el("Nuevo álbum"))
        let alerta = app.alerts["Nuevo álbum"]
        if alerta.waitForExistence(timeout: 10) {
            alerta.textFields.firstMatch.typeText("Viaje")
            paso(11, "Vistas/VistaGaleria.swift", "private func crearAlbum")
            alerta.buttons["Crear"].tap()
        }

        // Grabadora: permiso de micrófono (Info.plist: NSMicrophoneUsageDescription)
        toca(app.tabBars.buttons["Grabadora"])
        if trampolin.alerts.firstMatch.waitForExistence(timeout: 8) {
            paso(12, "Info.plist", "NSMicrophoneUsageDescription")
        }
        aceptarPermisos()
        toca(el("Alta"))
        sleep(1)
        paso(13, "Servicios/ServicioAudio.swift", "enum Sensibilidad")

        let grabar = app.buttons["Grabar"]
        if grabar.waitForExistence(timeout: 5) && grabar.isEnabled {
            grabar.tap()
            sleep(4)
            paso(14, "Servicios/ServicioAudio.swift", "Si después de 1.5 s")
            if app.buttons["Aceptar"].exists { app.buttons["Aceptar"].tap() }
        }

        toca(app.tabBars.buttons["Ajustes"])
        toca(el("Azul (ESCOM)"))
        sleep(1)
        paso(15, "Vistas/Pestanas.swift", "struct VistaAjustes")

        toca(app.tabBars.buttons["Galería"])
        toca(app.buttons["Exportar"])
        sleep(4)
        paso(16, "Datos/AlmacenMedios.swift", "enum AlmacenMedios")
    }

    /// Repetición de los pasos 4 (cuenta regresiva), 7 (galería) y 10 (reproductor), y dos
    /// pasos en modo oscuro (el simulador se cambia a oscuro desde la Mac antes de correr).
    func testRepetir() {
        aceptarPermisos()
        toca(app.buttons["Temporizador"])
        toca(el("10 segundos"))
        toca(app.buttons["Tomar foto"])
        sleep(2)
        paso(4, "Vistas/VistaCamara.swift", "private func disparar")
        if app.buttons["Cancel"].waitForExistence(timeout: 5) { app.buttons["Cancel"].tap() }
        sleep(1)

        toca(app.tabBars.buttons["Galería"])
        sleep(3)
        paso(7, "Vistas/VistaGaleria.swift", "struct VistaGaleria")

        let audio = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'medio_Audios/'")).firstMatch
        toca(audio)
        toca(app.buttons["Reproducir"])
        sleep(1)
        paso(10, "Servicios/ServicioAudio.swift", "final class Reproductor")
        if app.buttons["Pausar"].exists { app.buttons["Pausar"].tap() }
        regresar()

        // Modo oscuro
        senal(0, "", "OSCURO")
        sleep(3)
        paso(17, "Vistas/VistaGaleria.swift", "struct VistaGaleria")
        toca(app.tabBars.buttons["Ajustes"])
        toca(el("Azul (ESCOM)"))
        sleep(2)
        paso(18, "Modelo/Tema.swift", "var uiColor")
        senal(0, "", "CLARO")
        sleep(2)
    }

    // MARK: Ayudantes

    /// Pide a la Mac que abra el archivo en Xcode y espera a que se tome la captura.
    private func paso(_ numero: Int, _ archivo: String, _ patron: String) {
        senal(numero, archivo, patron)
        sleep(pausa)
    }

    private func senal(_ numero: Int, _ archivo: String, _ patron: String) {
        guard let casa = ProcessInfo.processInfo.environment["SIMULATOR_HOST_HOME"] else { return }
        let url = URL(fileURLWithPath: casa).appendingPathComponent("capturas/paso.txt")
        try? "\(numero)|\(archivo)|\(patron)".write(to: url, atomically: true, encoding: .utf8)
    }

    private func aceptarPermisos() {
        for _ in 0..<3 {
            let alerta = trampolin.alerts.firstMatch
            guard alerta.waitForExistence(timeout: 4) else { return }
            for texto in ["Allow While Using App", "Allow", "OK", "Permitir"] where alerta.buttons[texto].exists {
                alerta.buttons[texto].tap()
                break
            }
            sleep(1)
        }
    }

    private func el(_ texto: String) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier == %@ OR label == %@", texto, texto))
            .firstMatch
    }

    private func toca(_ elemento: XCUIElement, tocar: Bool = true) {
        guard elemento.waitForExistence(timeout: 15), tocar else { return }
        if elemento.isHittable { elemento.tap() } else { elemento.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap() }
    }

    private func regresar() {
        let atras = app.navigationBars.buttons.element(boundBy: 0)
        if atras.waitForExistence(timeout: 10) { atras.tap() }
    }
}
