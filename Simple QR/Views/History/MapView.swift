//
//  MapView.swift
//  QR Unveil
//
//  Created by Stéphane PAQUET on 4/3/25.
//

import SwiftUI

// Displays a map with markers where the QR codes were scanned.
// There should be a filter by region, coutry and for large coutries such as USA, China, Russia, Australia we should offer to narrow the scope.
// Thee should be a time filter (only the past so we should offer today, past 3 days, ...) and display the dates so the user know.
// When multiple QR codes are scanned in one location let's display the number
// Tapping the marker should open the QRCodeDetailView when there is only 1 QR Code for that marker or a list so that the user can select the one they want to have more information. For the list we should try to reuse HistoryView in order to minimize the amount of code and redundant code in the app.
struct MapView: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    MapView()
}
