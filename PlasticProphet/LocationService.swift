import Foundation
import CoreLocation
import Combine

/// Central place for all CoreLocation logic.
/// - Requests permission
/// - Tracks authorization status
/// - Tracks the last known location
/// - Monitors geofences for test merchants (Phase 1)
class LocationService: NSObject, ObservableObject {
    
    // MARK: - Published Properties (Observable by SwiftUI)
    
    /// Current iOS-level authorization status
    @Published var authorizationStatus: CLAuthorizationStatus
    
    /// Last location received from CoreLocation
    @Published var lastLocation: CLLocation?
    
    /// Convenience: last coordinate only (lat/lon)
    var lastCoordinate: CLLocationCoordinate2D? {
        lastLocation?.coordinate
    }
    
    // MARK: - Private
    
    /// Underlying CoreLocation manager
    private let manager: CLLocationManager
    
    /// Merchants we are currently monitoring with geofences.
    private var monitoredMerchants: [TestMerchant] = []
    
    // MARK: - Callbacks
    
    /// Optional callback that lets AppState (or others) react to geofence events.
    /// When a region is entered, we pass the merchant name.
    var onMerchantRegionEntered: ((String) -> Void)?
    
    // MARK: - Init
    
    override init() {
        self.manager = CLLocationManager()
        self.authorizationStatus = manager.authorizationStatus
        super.init()
        
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }
    
    // MARK: - Permission Requests
    
    /// Refresh the current authorization status from the location manager
    func refreshAuthorizationStatus() {
        authorizationStatus = manager.authorizationStatus
    }
    
    /// Ask iOS for "While Using the App" location access.
    /// This will trigger the system popup if status is `.notDetermined`.
    func requestWhenInUseAuthorization() {
        manager.requestWhenInUseAuthorization()
    }
    
    /// Request "Always" access for background location.
    /// Per Apple docs, you must first have "When In Use" authorization before requesting "Always".
    /// If status is notDetermined, this will first show the "When In Use" prompt.
    /// If status is authorizedWhenInUse, this will show the "Upgrade to Always" prompt.
    func requestAlwaysAuthorization() {
        // Refresh status first to ensure we have the latest
        let currentStatus = manager.authorizationStatus
        authorizationStatus = currentStatus
        
        switch currentStatus {
        case .notDetermined:
            // Must request WhenInUse first per Apple's requirements
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            // Now we can request upgrade to Always
            manager.requestAlwaysAuthorization()
        case .authorizedAlways:
            // Already have Always, nothing to do
            break
        default:
            // Denied or restricted - can't request
            break
        }
    }
    
    // MARK: - Location Updates
    
    /// Start location updates only if authorized.
    func startUpdatingLocationIfAuthorized() {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        default:
            break
        }
    }
    
    func stopUpdatingLocation() {
        manager.stopUpdatingLocation()
    }
    
    // MARK: - Geofencing (Phase 1 Test Merchants)
    
    /// Register geofences for our Phase 1 test merchants.
    /// Call this only after we have location authorization.
    private func registerGeofencesForTestMerchants() {
        // Stop monitoring any existing regions first
        for region in manager.monitoredRegions {
            manager.stopMonitoring(for: region)
        }
        
        monitoredMerchants = testMerchants
        
        for merchant in monitoredMerchants {
            let region = CLCircularRegion(
                center: merchant.coordinate,
                radius: merchant.radius,
                identifier: merchant.id
            )
            region.notifyOnEntry = true
            region.notifyOnExit = false
            
            manager.startMonitoring(for: region)
            print("🔵 Started monitoring region for \(merchant.name) (\(merchant.id))")
        }
    }
    
    // MARK: - Convenience Text (optional for UI)
    
    /// Human-readable string for the current authorization status.
    var statusDescription: String {
        switch authorizationStatus {
        case .notDetermined:
            return "Location: Not Determined"
        case .restricted:
            return "Location: Restricted"
        case .denied:
            return "Location: Denied"
        case .authorizedWhenInUse:
            return "Location: While Using"
        case .authorizedAlways:
            return "Location: Always"
        @unknown default:
            return "Location: Unknown"
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {
    
    /// Called whenever authorization changes (iOS 14+)
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        startUpdatingLocationIfAuthorized()
        
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            registerGeofencesForTestMerchants()
        default:
            break
        }
    }
    
    /// Older callback (still useful on some systems)
    func locationManager(_ manager: CLLocationManager,
                         didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        startUpdatingLocationIfAuthorized()
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            registerGeofencesForTestMerchants()
        default:
            break
        }
    }
    
    /// Updates when the user changes physical location (GPS)
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        lastLocation = location
        // print("📍 Updated location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
    }
    
    /// Called if location updates fail
    func locationManager(_ manager: CLLocationManager,
                         didFailWithError error: Error) {
        print("LocationService error: \(error.localizedDescription)")
    }
    
    /// Called when entering a monitored geofence region.
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("✅ didEnterRegion fired for identifier: \(region.identifier)")
        
        // Match region identifier → TestMerchant
        if let merchant = monitoredMerchants.first(where: { $0.id == region.identifier }) {
            print("📍 Entered geofence for merchant: \(merchant.name)")
            
            // Notify whoever is listening (AppState) so it can fetch a recommendation.
            onMerchantRegionEntered?(merchant.name)
            
        } else {
            print("⚠️ Entered unknown region: \(region.identifier)")
        }
    }
}
