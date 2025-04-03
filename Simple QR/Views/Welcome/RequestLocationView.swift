//
//  RequestLocationView.swift
//  QR Unveil
//
//  Created by Stéphane PAQUET on 4/3/25.
//

import SwiftUI

// This view explains to the user that they can save the where in addition to the when they scanned a QR code. This could be important for some cases.
// There should be a skip for now button in addition to the grant button
// In case the user decides to skip for now we need to save this information in UserDefault and the view will be presented again when the user click on the location icon when saving a QR code.
// The view will be used to either request or to alert the user that the access to the location service is no longer granted while it was previously granted.
struct RequestLocationView: View {
    var body: some View {
        Image(systemName: "map")
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    RequestLocationView()
}
