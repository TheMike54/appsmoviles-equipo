import SwiftUI

/// Punto de entrada de la app de cámara y micrófono.
@main
struct CamaraMicrofonoApp: App {
    @State private var ubicacion = Ubicacion()
    private let persistencia = Persistencia.compartida

    init() {
        // Las pruebas de interfaz abren la app con este argumento para empezar siempre
        // desde el mismo estado (solo el contenido de ejemplo).
        if CommandLine.arguments.contains("-reiniciarDemo") {
            ContenidoDeEjemplo.reiniciar()
        }
        ContenidoDeEjemplo.crearSiHaceFalta()
    }

    var body: some Scene {
        WindowGroup {
            VistaPrincipal()
                .environment(\.managedObjectContext, persistencia.contexto)
                .environment(ubicacion)
        }
    }
}
