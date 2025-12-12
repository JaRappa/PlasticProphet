//  PlasticProphet
//  PermissionManager.swift
//  Created by Caroline Zanuto on 11/28/25.

import Foundation
import AVFoundation // For Camera
import CoreLocation // For Location
import SwiftUI

// Observable class to handle system permissions
class PermissionManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var cameraStatus: AVAuthorizationStatus = .notDetermined
    @Published var locationStatus: CLAuthorizationStatus = .notDetermined
    
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        locationManager.delegate = self
        checkCameraStatus()
        checkLocationStatus()
    }
    
    // MARK: - Camera Logic
    func checkCameraStatus() {
        cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
    }
    
    func requestCameraPermission() async {
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        await MainActor.run {
            self.cameraStatus = granted ? .authorized : .denied
        }
    }
    
    // MARK: - Location Logic
    func checkLocationStatus() {
        locationStatus = locationManager.authorizationStatus
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    // Delegate method called when location status changes
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        self.locationStatus = manager.authorizationStatus
    }
}
