import XCTest

/// Pruebas de interfaz de la app de cámara y micrófono. Recorren cada función y guardan una
/// captura por paso (adjunta a la prueba y en `~/capturas/ej3/` de la Mac).
/// Cada prueba abre la app con `-reiniciarDemo`: solo queda el contenido de ejemplo.
final class CamaraMicrofonoUITests: XCTestCase {
    private var app: XCUIApplication!
    private let trampolin = XCUIApplication(bundleIdentifier: "com.apple.springboard")

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        app = XCUIApplication()
        app.launchArguments = ["-reiniciarDemo"]
        app.launch()
    }

    // MARK: Cámara, permisos, flash, temporizador y filtros

    func test01_CamaraYFiltros() {
        aceptarPermisos(prefijo: "01_permiso")
        esperar(el("Este dispositivo no tiene cámara"))
        captura("02_camara_sin_dispositivo")

        toca(app.buttons["Flash"])
        esperar(el("Encendido"))
        captura("03_menu_flash")
        toca(el("Encendido"))

        toca(app.buttons["Temporizador"])
        esperar(el("3 segundos"))
        captura("04_menu_temporizador")
        toca(el("3 segundos"))
        captura("05_flash_y_temporizador_activos")

        toca(app.buttons["Tomar foto"])
        if el("cuentaRegresiva").waitForExistence(timeout: 3) { captura("06_cuenta_regresiva") }

        // Fuente alternativa: fototeca (PHPickerViewController)
        sleep(6)
        captura("07_fototeca_phpicker")
        // El selector corre en otro proceso: se toca la primera foto de la cuadrícula por su posición.
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.17, dy: 0.41)).tap()

        esperar(app.navigationBars["Nueva foto"], 30)
        sleep(2)
        captura("08_editor_sin_filtro")
        toca(el("filtro_sepia"))
        sleep(2)
        captura("09_editor_filtro_sepia")
        let etiquetas = app.textFields["Etiquetas (separadas por comas)"]
        toca(etiquetas)
        etiquetas.typeText("prueba, fototeca\n")
        toca(app.buttons["Guardar"])
        esperarQueDesaparezca(app.navigationBars["Nueva foto"])

        toca(app.tabBars.buttons["Galería"])
        sleep(2)
        captura("10_galeria_con_foto_nueva")
    }

    // MARK: Grabadora

    func test02_Grabadora() {
        toca(app.tabBars.buttons["Grabadora"])
        aceptarPermisos(prefijo: "11_permiso")
        sleep(2)
        captura("12_grabadora")
        toca(el("Alta"))
        let temporizador = el("Temporizador")
        toca(temporizador)
        if el("30 s").waitForExistence(timeout: 5) {
            captura("13_temporizador_grabacion")
            toca(el("30 s"))
        }
        sleep(1)
        captura("14_grabadora_opciones")

        // Grabación de prueba de 3 segundos
        let grabar = app.buttons["Grabar"]
        if grabar.isEnabled {
            toca(grabar)
            sleep(3)
            captura("14b_grabando")
            if app.buttons["Detener grabación"].exists { toca(app.buttons["Detener grabación"]) }
            sleep(2)
            captura("14c_despues_de_grabar")
        }
    }

    // MARK: Galería, álbumes, detalle, edición y reproductor

    func test03_Galeria() {
        aceptarPermisos(prefijo: nil)
        toca(app.tabBars.buttons["Galería"])
        sleep(3)
        captura("15_galeria")

        toca(el("ESCOM (2)"))
        sleep(1)
        captura("16_album_escom")
        toca(el("Todos los álbumes"))

        toca(el("Audios"))
        sleep(1)
        captura("17_filtro_audios")
        toca(el("Todo"))

        // Detalle de una foto con metadatos
        let foto = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'medio_Fotos/'")).firstMatch
        toca(foto)
        esperar(el("Fecha"))
        sleep(2)
        captura("18_detalle_foto_metadatos")

        // Edición básica
        toca(app.buttons["Editar"])
        esperar(app.navigationBars["Editar foto"])
        toca(el("filtro_noir"))
        toca(el("Girar"))
        sleep(2)
        captura("19_editar_foto")
        toca(app.buttons["Guardar"])
        sleep(2)
        captura("20_foto_editada")
        regresar()

        // Reproductor
        let audio = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'medio_Audios/'")).firstMatch
        toca(audio)
        esperar(app.buttons["Reproducir"])
        captura("21_reproductor")
        toca(app.buttons["Reproducir"])
        sleep(1)
        captura("22_reproduciendo")
        toca(app.buttons["Pausar"])
        regresar()

        // Menú contextual: mover a álbum
        foto.press(forDuration: 1.5)
        if el("Mover a álbum").waitForExistence(timeout: 5) {
            captura("23_menu_contextual")
            toca(el("Mover a álbum"))
            sleep(1)
            captura("24_mover_a_album")
            app.tap()
        }
    }

    func test04_ExportarEImportar() {
        aceptarPermisos(prefijo: nil)
        toca(app.tabBars.buttons["Galería"])
        toca(app.buttons["Exportar"])
        sleep(4)
        captura("25_exportar")
    }

    func test05_Importar() {
        aceptarPermisos(prefijo: nil)
        toca(app.tabBars.buttons["Galería"])
        toca(app.buttons["Agregar"])
        toca(el("Importar de Archivos"))
        sleep(5)
        captura("26_importar")
    }

    func test06_NuevoAlbum() {
        aceptarPermisos(prefijo: nil)
        toca(app.tabBars.buttons["Galería"])
        toca(app.buttons["Agregar"])
        toca(el("Nuevo álbum"))
        let alerta = app.alerts["Nuevo álbum"]
        esperar(alerta)
        alerta.textFields.firstMatch.typeText("Viaje")
        captura("27_nuevo_album")
        toca(alerta.buttons["Crear"])
        esperar(el("Viaje (0)"))
        captura("28_album_creado")
    }

    // MARK: Temas

    func test07_Temas() {
        aceptarPermisos(prefijo: nil)
        let modo = UITraitCollection.current.userInterfaceStyle == .dark ? "oscuro" : "claro"
        toca(app.tabBars.buttons["Galería"])
        sleep(2)
        captura("29_tema_guinda_\(modo)")
        toca(app.tabBars.buttons["Ajustes"])
        toca(el("Azul (ESCOM)"))
        sleep(1)
        captura("30_ajustes_azul_\(modo)")
        toca(app.tabBars.buttons["Grabadora"])
        sleep(2)
        captura("31_tema_azul_\(modo)")
    }

    // MARK: Ayudantes

    /// Acepta los avisos de permisos del sistema (cámara, ubicación, micrófono) que aparezcan.
    private func aceptarPermisos(prefijo: String?) {
        var n = 0
        for _ in 0..<4 {
            let alerta = trampolin.alerts.firstMatch
            guard alerta.waitForExistence(timeout: 6) else { break }
            n += 1
            if let prefijo { captura("\(prefijo)_\(n)") }
            for texto in ["Allow While Using App", "Permitir al usarse la app", "OK", "Permitir", "Allow"]
            where alerta.buttons[texto].exists {
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

    private func esperar(_ elemento: XCUIElement, _ segundos: TimeInterval = 20, file: StaticString = #filePath, line: UInt = #line) {
        if !elemento.waitForExistence(timeout: segundos) {
            captura("fallo_linea_\(line)")
            XCTFail("No apareció: \(elemento)\n\(app.debugDescription.prefix(3000))", file: file, line: line)
        }
    }

    private func esperarQueDesaparezca(_ elemento: XCUIElement, _ segundos: TimeInterval = 30) {
        let espera = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: elemento)
        XCTAssertEqual(XCTWaiter().wait(for: [espera], timeout: segundos), .completed)
    }

    private func toca(_ elemento: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
        esperar(elemento, file: file, line: line)
        if elemento.isHittable {
            elemento.tap()
        } else {
            elemento.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
    }

    private func regresar() {
        let atras = app.navigationBars.buttons.element(boundBy: 0)
        esperar(atras)
        atras.tap()
    }

    private func captura(_ nombre: String) {
        let imagen = XCUIScreen.main.screenshot()
        let adjunto = XCTAttachment(screenshot: imagen)
        adjunto.name = "ej3_\(nombre)"
        adjunto.lifetime = .keepAlways
        add(adjunto)
        if let casa = ProcessInfo.processInfo.environment["SIMULATOR_HOST_HOME"] {
            let carpeta = URL(fileURLWithPath: casa).appendingPathComponent("capturas/ej3", isDirectory: true)
            try? FileManager.default.createDirectory(at: carpeta, withIntermediateDirectories: true)
            try? imagen.pngRepresentation.write(to: carpeta.appendingPathComponent("ej3_\(nombre).png"))
        }
    }
}
