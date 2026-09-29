import XCTest

/// Recorrido guiado para tomar capturas "código + app": en cada paso deja la app en una
/// pantalla y pide (con un archivo de señal) que Xcode muestre el código correspondiente;
/// luego espera unos segundos para tomar la captura.
///
/// Solo corre si se define la variable `TEST_RUNNER_RECORRIDO=1` al ejecutar `xcodebuild test`;
/// en una ejecución normal de las pruebas se omite.
final class RecorridoParaCapturas: XCTestCase {
    private var app: XCUIApplication!
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
        paso(1, "Vistas/Pestanas.swift", "struct VistaExplorar")

        toca(el("Documentos"))
        paso(2, "Servicios/ServicioArchivos.swift", "func listar")

        el("Bienvenida.txt").press(forDuration: 1.5)
        paso(3, "Vistas/VistaCarpeta.swift", "func menuContextual")
        app.tap()
        sleep(1)
        if el("Renombrar").exists { app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1)).tap() }

        toca(el("Bienvenida.txt"))
        paso(4, "Vistas/Visores.swift", "struct VisorTexto")
        regresar()

        toca(el("Imágenes"))
        sleep(2)
        paso(5, "Servicios/CacheMiniaturas.swift", "func miniatura")

        toca(el("Paisaje.png"))
        let imagen = app.images.firstMatch
        _ = imagen.waitForExistence(timeout: 10)
        imagen.pinch(withScale: 1.4, velocity: 1)
        paso(6, "Vistas/Visores.swift", "struct VisorImagen")
        regresar()

        toca(el("foto_dañada.png"))
        paso(7, "Servicios/ServicioArchivos.swift", "enum ErrorArchivo")
        regresar(); regresar()

        toca(el("Documentos"))
        toca(el("Guía de uso.pdf"))
        sleep(6)
        paso(8, "Vistas/Visores.swift", "struct VisorQuickLook")
        for texto in ["OK", "Listo", "Done"] where app.buttons[texto].exists { app.buttons[texto].tap(); break }
        sleep(1)
        regresar(); regresar()

        toca(app.buttons["Agregar"])
        toca(el("Nueva carpeta"))
        let alerta = app.alerts["Nueva carpeta"]
        if alerta.waitForExistence(timeout: 10) {
            alerta.textFields.firstMatch.typeText("Proyectos")
            paso(9, "Servicios/ServicioArchivos.swift", "func crearCarpeta")
            alerta.buttons["Crear"].tap()
        }

        let celda = app.cells.containing(.staticText, identifier: "Bienvenida.txt").firstMatch
        celda.swipeLeft()
        paso(10, "Vistas/VistaCarpeta.swift", ".swipeActions")
        app.buttons.matching(NSPredicate(format: "label == 'Eliminar'")).firstMatch.tap()
        sleep(2)
        paso(11, "Vistas/VistaCarpeta.swift", ".confirmationDialog")
        let cancelar = app.buttons["Cancelar"]
        if cancelar.exists { cancelar.tap() }

        let buscar = app.searchFields.firstMatch
        if !buscar.exists || !buscar.isHittable { app.cells.firstMatch.swipeDown() }
        if buscar.waitForExistence(timeout: 5) {
            toca(buscar)
            buscar.typeText("Bien")
            paso(12, "Vistas/VistaCarpeta.swift", "private var visibles")
            if app.buttons["Cancelar"].exists { app.buttons["Cancelar"].firstMatch.tap() }
        }

        toca(el("Imágenes"))
        toca(app.buttons["Ordenar y vista"])
        toca(el("Ver como cuadrícula"))
        sleep(2)
        paso(13, "Modelo/ElementoArchivo.swift", "enum Orden")
        regresar(); regresar()

        toca(el("Documentos"))
        el("Notas").press(forDuration: 1.5)
        toca(el("Agregar a favoritos"))
        toca(app.tabBars.buttons["Favoritos"])
        sleep(1)
        paso(14, "Servicios/Preferencias.swift", "func alternarFavorito")

        toca(app.tabBars.buttons["Ajustes"])
        toca(el("Azul (ESCOM)"))
        sleep(1)
        paso(15, "Modelo/Tema.swift", "var uiColor")

        toca(app.tabBars.buttons["Explorar"])
        paso(16, "Info.plist", "UIFileSharingEnabled")

        toca(el("Documentos"))
        toca(app.buttons["Agregar"])
        toca(el("Importar archivos"))
        sleep(4)
        paso(17, "Vistas/PuentesUIKit.swift", "struct SelectorDocumentos")
    }

    /// Repetición de los pasos 6 (zoom) y 15 (tema azul).
    func testRepetirZoomYTema() {
        toca(el("Documentos"))
        toca(el("Imágenes"))
        toca(el("Paisaje.png"))
        let imagen = app.images.firstMatch
        _ = imagen.waitForExistence(timeout: 10)
        sleep(1)
        imagen.pinch(withScale: 1.4, velocity: 1)
        paso(6, "Vistas/Visores.swift", "struct VisorImagen")
        regresar(); regresar(); regresar()

        toca(app.tabBars.buttons["Ajustes"])
        toca(el("Azul (ESCOM)"))
        sleep(2)
        paso(15, "Modelo/Tema.swift", "var uiColor")
    }

    /// Capturas en modo oscuro (el vigía de la Mac cambia la apariencia del simulador).
    func testModoOscuro() {
        senal("OSCURO")
        sleep(3)
        paso(19, "Vistas/Pestanas.swift", "struct VistaExplorar")
        toca(el("Documentos"))
        toca(el("Imágenes"))
        sleep(2)
        paso(20, "Vistas/VistaCarpeta.swift", "struct FilaElemento")
        toca(app.tabBars.buttons["Ajustes"])
        toca(el("Azul (ESCOM)"))
        sleep(2)
        paso(21, "Modelo/Tema.swift", "var uiColor")
        toca(app.tabBars.buttons["Explorar"])
        sleep(2)
        paso(22, "Vistas/VistaCarpeta.swift", "struct Miniatura")
        senal("CLARO")
        sleep(2)
    }

    private func senal(_ modo: String) {
        guard let casa = ProcessInfo.processInfo.environment["SIMULATOR_HOST_HOME"] else { return }
        try? "0||\(modo)".write(to: URL(fileURLWithPath: casa).appendingPathComponent("capturas/paso.txt"), atomically: true, encoding: .utf8)
    }

    // MARK: Ayudantes

    /// Pide a la Mac que abra el archivo en Xcode (en la línea que contiene `patron`) y espera
    /// a que se tome la captura.
    private func paso(_ numero: Int, _ archivo: String, _ patron: String) {
        guard let casa = ProcessInfo.processInfo.environment["SIMULATOR_HOST_HOME"] else { return }
        let senal = URL(fileURLWithPath: casa).appendingPathComponent("capturas/paso.txt")
        try? "\(numero)|\(archivo)|\(patron)".write(to: senal, atomically: true, encoding: .utf8)
        sleep(pausa)
    }

    private func el(_ texto: String) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier == %@ OR label == %@", texto, texto))
            .firstMatch
    }

    private func toca(_ elemento: XCUIElement) {
        guard elemento.waitForExistence(timeout: 15) else { return }
        if elemento.isHittable { elemento.tap() } else { elemento.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap() }
    }

    private func regresar() {
        let atras = app.navigationBars.buttons.element(boundBy: 0)
        if atras.waitForExistence(timeout: 10) { atras.tap() }
    }
}
