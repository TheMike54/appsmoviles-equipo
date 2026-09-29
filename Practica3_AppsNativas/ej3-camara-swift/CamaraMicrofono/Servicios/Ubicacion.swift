import CoreLocation
import Observation

/// Obtiene la ubicación actual (una sola lectura) para guardarla como metadato de cada
/// foto o grabación. Solo guarda coordenadas: convertirlas en dirección requiere internet.
@Observable
final class Ubicacion: NSObject, CLLocationManagerDelegate {
    private let administrador = CLLocationManager()
    private(set) var ultima: CLLocation?

    override init() {
        super.init()
        administrador.delegate = self
        administrador.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func solicitar() {
        switch administrador.authorizationStatus {
        case .notDetermined: administrador.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways: administrador.requestLocation()
        default: break
        }
    }

    var coordenadas: (Double, Double)? {
        guard let ultima else { return nil }
        return (ultima.coordinate.latitude, ultima.coordinate.longitude)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        ultima = locations.last
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
}
