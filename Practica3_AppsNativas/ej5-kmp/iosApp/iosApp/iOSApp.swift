import SwiftUI

/// Punto de entrada de la app de iOS. El estado (archivos, favoritos, recientes, tema y
/// orden) vive en FileBrowserModel y se comparte con todas las pantallas.
@main
struct iOSApp: App {
    @StateObject private var model = FileBrowserModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
        }
    }
}
