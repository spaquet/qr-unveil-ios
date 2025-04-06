//
//  LocationManager.swift
//  Simple QR
//
//  Created by Stéphane PAQUET on 4/3/25.
//

import Foundation
import CoreLocation
import SwiftUI

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var location: CLLocation?
    
    static let shared = LocationManager()
    
    override init() {
            super.init()
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            authorizationStatus = locationManager.authorizationStatus
        }
    
//    override init() {
//        super.init()
//        locationManager.delegate = self
//        locationManager.desiredAccuracy = kCLLocationAccuracyBest
//    }
    
    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    // CLLocationManagerDelegate methods
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        
        // Start updating location if authorized
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            self.location = location
        }
    }
    
    // Check if location permission is granted
    var isAuthorized: Bool {
        return authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }
    
    // Start or stop location updates
    func startLocationUpdates() {
        if isAuthorized {
            locationManager.startUpdatingLocation()
        }
    }
    
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
    }
}
