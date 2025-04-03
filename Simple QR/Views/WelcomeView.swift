//
//  WelcomeView.swift
//  QR Unveil
//
//  Created by Stéphane PAQUET on 4/3/25.
//

import SwiftUI


// This view is only displayed when the app is opened for the first time on the device.
struct WelcomeView: View {
    var body: some View {
        Image(systemName: "qrcode")
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
        // button to move to RewuestCameraView next
    }
}

#Preview {
    WelcomeView()
}
