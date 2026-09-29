import XCTest

/// Pruebas de interfaz: recorren las funciones del gestor como lo haría un usuario y guardan
/// una captura de pantalla en cada paso. Cada prueba abre la app con `-reiniciarDemo` para
/// empezar con los archivos de ejemplo y sin preferencias guardadas.
///
/// Las capturas se adjuntan al resultado de la prueba y, al correr en el simulador, también se
/// guardan en `~/capturas/ej2/` de la Mac.
final class GestorArchivosUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        app = XCUIApplication()
        app.launchArguments = ["-reiniciarDemo"]
        app.launch()
    }

    // MARK: Navegación y visores

    func test01_NavegacionYVisores() {
        esperar(el("Documentos"))
        captura("01_raiz_sandbox")

        toca(el("Documentos"))
        esperar(el("Bienvenida.txt"))
        captura("02_documentos_ruta")

        toca(el("Bienvenida.txt"))
        esperar(app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Bienvenido'")).firstMatch)
        captura("03_visor_texto")
        regresar()

        toca(el("Código"))
        toca(el("Ejemplo.swift"))
        esperar(app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'FileManager'")).firstMatch)
        captura("04_visor_codigo")
        regresar(); regresar()

        toca(el("Imágenes"))
        esperar(el("Paisaje.png"))
        sleep(2)
        captura("05_imagenes_miniaturas")

        toca(el("Paisaje.png"))
        let imagen = app.images.firstMatch
        esperar(imagen)
        captura("06_visor_imagen")
        imagen.pinch(withScale: 1.3, velocity: 1)
        imagen.rotate(0.35, withVelocity: 0.5)
        sleep(1)
        captura("07_visor_imagen_zoom_rotacion")
        regresar()

        toca(el("foto_dañada.png"))
        esperar(el("No se puede abrir"))
        captura("08_error_archivo_danado")
        regresar(); regresar()

        toca(el("Documentos"))
        toca(el("Guía de uso.pdf"))
        sleep(8)
        captura("09_quick_look_pdf")
    }

    // MARK: Gestión de archivos

    func test02_GestionDeArchivos() {
        toca(el("Documentos"))
        esperar(el("Bienvenida.txt"))

        // Crear carpeta
        toca(app.buttons["Agregar"])
        toca(app.buttons["Nueva carpeta"])
        let alerta = app.alerts["Nueva carpeta"]
        esperar(alerta)
        alerta.textFields.firstMatch.typeText("Proyectos")
        captura("10_crear_carpeta")
        toca(alerta.buttons["Crear"])
        esperar(el("Proyectos"))

        // Menú contextual (mantener presionado)
        el("Bienvenida.txt").press(forDuration: 1.5)
        esperar(app.buttons["Renombrar"])
        captura("11_menu_contextual")

        // Renombrar
        toca(app.buttons["Renombrar"])
        let renombrar = app.alerts["Renombrar"]
        esperar(renombrar)
        let campo = renombrar.textFields.firstMatch
        campo.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 20) + "Léeme.txt")
        captura("12_renombrar")
        toca(renombrar.buttons["Guardar"])
        esperar(el("Léeme.txt"))

        // Copiar a otra carpeta
        el("Léeme.txt").press(forDuration: 1.5)
        toca(app.buttons["Copiar a…"])
        esperar(app.navigationBars["Copiar a…"])
        toca(el("Proyectos"))
        captura("13_copiar_elegir_destino")
        toca(app.buttons["Copiar aquí"])

        // Mover a otra carpeta
        el("Léeme.txt").press(forDuration: 1.5)
        toca(app.buttons["Mover a…"])
        toca(el("Notas"))
        captura("14_mover_elegir_destino")
        toca(app.buttons["Mover aquí"])
        esperarQueDesaparezca(el("Léeme.txt"))

        // Resultado: la copia quedó en Proyectos
        toca(el("Proyectos"))
        esperar(el("Léeme.txt"))
        captura("15_resultado_copia_en_proyectos")

        // Deslizar para eliminar, con confirmación
        let celda = app.cells.containing(.staticText, identifier: "Léeme.txt").firstMatch
        celda.swipeLeft()
        esperar(app.buttons["Eliminar"])
        captura("16_deslizar_para_eliminar")
        toca(app.buttons["Eliminar"])
        esperar(el("¿Eliminar «Léeme.txt»?"))
        captura("17_confirmar_eliminar")
        let botones = app.buttons.matching(NSPredicate(format: "label == 'Eliminar'"))
        toca(botones.element(boundBy: botones.count - 1))
        esperar(el("Carpeta vacía"))
        captura("18_carpeta_vacia")
    }

    // MARK: Búsqueda, orden, vista y actualización

    func test03_BusquedaOrdenYVista() {
        toca(el("Documentos"))
        toca(el("Imágenes"))
        esperar(el("Paisaje.png"))

        // Ordenar por tamaño
        toca(app.buttons["Ordenar y vista"])
        esperar(app.buttons["Tamaño"])
        captura("19_menu_ordenar")
        toca(app.buttons["Tamaño"])
        sleep(1)
        captura("20_ordenado_por_tamano")

        // Buscar
        let buscar = app.searchFields.firstMatch
        if !buscar.waitForExistence(timeout: 3) || !buscar.isHittable { app.cells.firstMatch.swipeDown() }
        toca(buscar)
        buscar.typeText("Logo")
        sleep(1)
        captura("21_busqueda")
        app.buttons["Cancelar"].firstMatch.tap()

        // Jalar para actualizar
        let inicio = app.cells.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
        let fin = inicio.withOffset(CGVector(dx: 0, dy: 350))
        inicio.press(forDuration: 0.1, thenDragTo: fin, withVelocity: .slow, thenHoldForDuration: 0.5)
        captura("22_jalar_para_actualizar")

        // Vista de cuadrícula
        toca(app.buttons["Ordenar y vista"])
        toca(app.buttons["Ver como cuadrícula"])
        sleep(2)
        captura("23_vista_cuadricula")
    }

    // MARK: Compartir e importar

    func test04_Compartir() {
        toca(el("Documentos"))
        toca(el("Imágenes"))
        el("Paisaje.png").press(forDuration: 1.5)
        toca(app.buttons["Compartir"])
        sleep(4)
        captura("24_hoja_compartir")
    }

    func test05_Importar() {
        toca(el("Documentos"))
        toca(app.buttons["Agregar"])
        toca(app.buttons["Importar archivos"])
        sleep(5)
        captura("25_importar_desde_archivos")
    }

    // MARK: Favoritos, recientes y preferencias guardadas

    func test06_FavoritosRecientesYPreferencias() {
        toca(el("Documentos"))
        el("Notas").press(forDuration: 1.5)
        toca(app.buttons["Agregar a favoritos"])
        toca(el("Imágenes"))
        el("Logo IPN.png").press(forDuration: 1.5)
        toca(app.buttons["Agregar a favoritos"])
        toca(el("Paisaje.png"))
        esperar(app.images.firstMatch)
        regresar()
        toca(el("Logo ESCOM.png"))
        esperar(app.images.firstMatch)
        regresar()

        toca(app.tabBars.buttons["Recientes"])
        esperar(el("Logo ESCOM.png"))
        captura("26_recientes")
        toca(app.tabBars.buttons["Favoritos"])
        esperar(el("Notas"))
        captura("27_favoritos")

        // Al volver a abrir la app se restaura la última carpeta visitada (Imágenes).
        app.terminate()
        app.launchArguments = []
        app.launch()
        esperar(el("Paisaje.png"))
        captura("28_restaura_ultima_carpeta")
    }

    // MARK: Orientación horizontal

    func test07_Horizontal() {
        toca(el("Documentos"))
        toca(el("Imágenes"))
        esperar(el("Paisaje.png"))
        XCUIDevice.shared.orientation = .landscapeLeft
        sleep(3)
        captura("29_horizontal")
        XCUIDevice.shared.orientation = .portrait
    }

    // MARK: Temas

    /// Captura los dos temas; el modo claro/oscuro lo decide el simulador al correr la prueba.
    func test08_Temas() {
        let modo = UITraitCollection.current.userInterfaceStyle == .dark ? "oscuro" : "claro"
        toca(el("Documentos"))
        esperar(el("Bienvenida.txt"))
        captura("30_tema_guinda_\(modo)")

        toca(app.tabBars.buttons["Ajustes"])
        toca(app.buttons["Azul (ESCOM)"])
        sleep(1)
        captura("31_ajustes_tema_azul_\(modo)")
        toca(app.tabBars.buttons["Explorar"])
        sleep(1)
        captura("32_tema_azul_\(modo)")
    }

    // MARK: App Archivos de iOS

    /// Abre la app Archivos del sistema para mostrar que la carpeta Documents de la app está expuesta.
    func test09_AppArchivos() {
        sleep(2)
        let archivos = XCUIApplication(bundleIdentifier: "com.apple.DocumentsApp")
        archivos.launch()
        sleep(4)
        for texto in ["Explorar", "Browse"] where archivos.tabBars.buttons[texto].exists {
            archivos.tabBars.buttons[texto].tap()
        }
        sleep(2)
        for texto in ["En mi iPhone", "On My iPhone"] where archivos.staticTexts[texto].exists {
            archivos.staticTexts[texto].tap()
            sleep(3)
        }
        captura("33_app_archivos_en_mi_iphone")
        if archivos.staticTexts["Gestor de Archivos"].exists {
            archivos.staticTexts["Gestor de Archivos"].tap()
            sleep(3)
            captura("34_app_archivos_carpeta_de_la_app")
        }
    }

    // MARK: Ayudantes

    private func esperar(_ elemento: XCUIElement, _ segundos: TimeInterval = 20, file: StaticString = #filePath, line: UInt = #line) {
        if !elemento.waitForExistence(timeout: segundos) {
            captura("fallo_linea_\(line)")
            XCTFail("No apareció: \(elemento)\n\(app.debugDescription.prefix(3000))", file: file, line: line)
        }
    }

    private func esperarQueDesaparezca(_ elemento: XCUIElement, _ segundos: TimeInterval = 20) {
        let predicado = NSPredicate(format: "exists == false")
        let espera = XCTNSPredicateExpectation(predicate: predicado, object: elemento)
        XCTAssertEqual(XCTWaiter().wait(for: [espera], timeout: segundos), .completed)
    }

    /// Busca un elemento por identificador de accesibilidad o por su texto exacto.
    private func el(_ texto: String) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier == %@ OR label == %@", texto, texto))
            .firstMatch
    }

    private func toca(_ elemento: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
        esperar(elemento, file: file, line: line)
        // Los menús de la barra superior no aceptan el toque por accesibilidad
        // ("failed to scroll to visible"); en ese caso se toca el centro del elemento.
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

    /// Adjunta la captura a la prueba y, en el simulador, la guarda también en ~/capturas/ej2 de la Mac.
    private func captura(_ nombre: String) {
        let imagen = XCUIScreen.main.screenshot()
        let adjunto = XCTAttachment(screenshot: imagen)
        adjunto.name = "ej2_\(nombre)"
        adjunto.lifetime = .keepAlways
        add(adjunto)
        if let casa = ProcessInfo.processInfo.environment["SIMULATOR_HOST_HOME"] {
            let carpeta = URL(fileURLWithPath: casa).appendingPathComponent("capturas/ej2", isDirectory: true)
            try? FileManager.default.createDirectory(at: carpeta, withIntermediateDirectories: true)
            try? imagen.pngRepresentation.write(to: carpeta.appendingPathComponent("ej2_\(nombre).png"))
        }
    }
}
