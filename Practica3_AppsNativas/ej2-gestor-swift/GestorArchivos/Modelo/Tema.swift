import SwiftUI
import UIKit

/// Temas de la app: Guinda (IPN) y Azul (ESCOM).
/// Cada tema tiene un color principal que se aclara en modo oscuro para mantener el contraste.
enum Tema: String, CaseIterable, Identifiable {
    case guinda
    case azul

    var id: String { rawValue }

    var nombre: String {
        switch self {
        case .guinda: return "Guinda (IPN)"
        case .azul: return "Azul (ESCOM)"
        }
    }

    /// Color principal: cambia automáticamente entre la variante clara y la oscura según el sistema.
    var color: Color {
        Color(uiColor: uiColor)
    }

    var uiColor: UIColor {
        switch self {
        case .guinda:
            return UIColor { rasgos in
                rasgos.userInterfaceStyle == .dark
                    ? UIColor(red: 0xD0 / 255, green: 0x6A / 255, blue: 0x9A / 255, alpha: 1) // guinda aclarado
                    : UIColor(red: 0x6C / 255, green: 0x1D / 255, blue: 0x45 / 255, alpha: 1) // #6C1D45
            }
        case .azul:
            return UIColor { rasgos in
                rasgos.userInterfaceStyle == .dark
                    ? UIColor(red: 0x6F / 255, green: 0x9F / 255, blue: 0xE0 / 255, alpha: 1) // azul aclarado
                    : UIColor(red: 0x0D / 255, green: 0x2F / 255, blue: 0x5A / 255, alpha: 1) // #0D2F5A
            }
        }
    }
}
