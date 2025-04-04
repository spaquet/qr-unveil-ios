//
//  MapLocationView.swift
//  Simple QR
//
//  Created by Stéphane PAQUET on 4/4/25.
//

import MapKit
import SwiftUI

// MARK: - Non-Interactive Map View
struct NonInteractiveMapLocationView: View {
    let latitude: Double
    let longitude: Double
    
    var body: some View {
        // Use MapKit for iOS 17+
        #if canImport(MapKit)
        Map {
            Marker(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                  label: { Text("Location") })
        }
        .mapStyle(.standard)
        .mapControls {
            // Intentionally leave empty to disable all controls
        }
        .allowsHitTesting(false) // This disables all user interaction with the map
        #else
        // Fallback for earlier iOS versions (though app targets iOS 17+)
        Text("Map")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.gray.opacity(0.2))
        #endif
    }
}
