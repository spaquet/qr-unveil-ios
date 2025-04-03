//
//  RequestCameraView.swift
//  QR Unveil
//
//  Created by Stéphane PAQUET on 4/3/25.
//

import SwiftUI

// This view explain to the user why we need access to the camera, even though it's pretty obvious that in order to scan a QR code and retrieve its raw value we need to scn it 🤣
// This view will also be used when the user does not grant us access to the camera as we cannot move forward
struct RequestCameraView: View {
    var body: some View {
        Image(systemName: "camera") // when requesting access
        Image(systemName: "exclamationmark.triangle") // when the user denies access to the camera. the app should then tell the user that it cannot perform and the user should be invited to go to the iPhone setting (link) to activate the camera for the app.
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    RequestCameraView()
}
