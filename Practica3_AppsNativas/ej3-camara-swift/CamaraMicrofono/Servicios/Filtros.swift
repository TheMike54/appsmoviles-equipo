import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

/// Filtros de foto con Core Image. Se aplican con un contexto de CPU para que funcionen
/// también en equipos sin GPU (como la Mac virtual del equipo).
enum Filtro: String, CaseIterable, Identifiable {
    case original, mono, sepia, noir, cromo, desvanecido, instantaneo, calido

    var id: String { rawValue }

    var nombre: String {
        switch self {
        case .original: return "Original"
        case .mono: return "Mono"
        case .sepia: return "Sepia"
        case .noir: return "Noir"
        case .cromo: return "Cromo"
        case .desvanecido: return "Desvanecido"
        case .instantaneo: return "Instantáneo"
        case .calido: return "Cálido"
        }
    }

    private static let contexto = CIContext(options: [.useSoftwareRenderer: true])

    /// Devuelve la imagen con el filtro aplicado (o la misma si es `.original`).
    func aplicar(a imagen: UIImage) -> UIImage {
        guard self != .original, let entrada = CIImage(image: imagen) else { return imagen }
        let salida: CIImage?
        switch self {
        case .original: salida = entrada
        case .mono: salida = efecto(CIFilter.photoEffectMono(), entrada)
        case .noir: salida = efecto(CIFilter.photoEffectNoir(), entrada)
        case .cromo: salida = efecto(CIFilter.photoEffectChrome(), entrada)
        case .desvanecido: salida = efecto(CIFilter.photoEffectFade(), entrada)
        case .instantaneo: salida = efecto(CIFilter.photoEffectInstant(), entrada)
        case .sepia:
            let f = CIFilter.sepiaTone(); f.inputImage = entrada; f.intensity = 0.9; salida = f.outputImage
        case .calido:
            let f = CIFilter.temperatureAndTint(); f.inputImage = entrada
            f.neutral = CIVector(x: 6500, y: 0); f.targetNeutral = CIVector(x: 4500, y: 0); salida = f.outputImage
        }
        guard let salida, let cg = Filtro.contexto.createCGImage(salida, from: entrada.extent) else { return imagen }
        return UIImage(cgImage: cg, scale: imagen.scale, orientation: imagen.imageOrientation)
    }
}

/// Aplica cualquiera de los efectos fotográficos de Core Image.
private func efecto(_ filtro: CIFilter & CIPhotoEffect, _ imagen: CIImage) -> CIImage? {
    filtro.inputImage = imagen
    return filtro.outputImage
}

extension UIImage {
    /// Reduce la imagen para previsualizar filtros rápido.
    func reducida(a lado: CGFloat) -> UIImage {
        let escala = min(1, lado / max(size.width, size.height))
        guard escala < 1 else { return self }
        let nuevo = CGSize(width: size.width * escala, height: size.height * escala)
        return UIGraphicsImageRenderer(size: nuevo).image { _ in draw(in: CGRect(origin: .zero, size: nuevo)) }
    }

    /// Gira la imagen 90° a la izquierda (edición básica).
    func girada90() -> UIImage {
        let nuevo = CGSize(width: size.height, height: size.width)
        return UIGraphicsImageRenderer(size: nuevo).image { ctx in
            ctx.cgContext.translateBy(x: nuevo.width / 2, y: nuevo.height / 2)
            ctx.cgContext.rotate(by: -.pi / 2)
            draw(in: CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height))
        }
    }

    /// Recorta al cuadrado central (edición básica).
    func recortadaCuadrada() -> UIImage {
        let lado = min(size.width, size.height)
        let origen = CGPoint(x: (size.width - lado) / 2, y: (size.height - lado) / 2)
        return UIGraphicsImageRenderer(size: CGSize(width: lado, height: lado)).image { _ in
            draw(at: CGPoint(x: -origen.x, y: -origen.y))
        }
    }
}
