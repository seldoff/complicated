import Foundation
import CoreLocation

class LocationProvider: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private var delegate: LocationManagerDelegate? = nil
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyReduced
        locationManager.requestWhenInUseAuthorization()
    }
    
    func getLocation() async throws -> CLLocation {
        return try await withCheckedThrowingContinuation { continuation in
            delegate = LocationManagerDelegate()
            
            delegate!.didUpdateLocations = { locations in
                if let location = locations.last {
                    continuation.resume(returning: location)
                } else {
                    continuation.resume(throwing: NSError(domain: "getLocation", code: -1, userInfo: [NSLocalizedDescriptionKey: "No location in locationManager"]))
                }
                self.delegate = nil
            }
            delegate!.didFailWithError = { error in
                continuation.resume(throwing: error)
                self.delegate = nil
            }
            
            locationManager.delegate = delegate
            locationManager.requestLocation()
        }
    }
}

private class LocationManagerDelegate: NSObject, CLLocationManagerDelegate {
    var didUpdateLocations: (([CLLocation]) -> Void)?
    var didFailWithError: ((Error) -> Void)?
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        didUpdateLocations?(locations)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        didFailWithError?(error)
    }
}
