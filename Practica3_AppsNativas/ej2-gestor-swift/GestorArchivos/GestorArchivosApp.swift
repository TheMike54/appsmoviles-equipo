import SwiftUI

/// Punto de entrada de la app. Crea los objetos compartidos (preferencias y ubicaciones
/// externas) y genera los archivos de ejemplo en el primer arranque.
@main
struct GestorArchivosApp: App {
    @State private var preferencias: Preferencias
    @State private var externas: UbicacionesExternas

    init() {
        // Las pruebas de interfaz abren la app con este argumento para empezar siempre
        // desde el mismo estado: sin preferencias guardadas y con los archivos de ejemplo.
        if CommandLine.arguments.contains("-reiniciarDemo") {
            ArchivosDeEjemplo.reiniciar()
        }
        ArchivosDeEjemplo.crearSiHaceFalta()
        // Se crean después del reinicio para que lean las preferencias ya limpias.
        _preferencias = State(initialValue: Preferencias())
        _externas = State(initialValue: UbicacionesExternas())
    }

    var body: some Scene {
        WindowGroup {
            VistaPrincipal()
                .environment(preferencias)
                .environment(externas)
        }
    }
}
