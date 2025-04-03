//
//  HistoryView.swift
//  QR Unveil
//
//  Created by Stéphane PAQUET on 4/2/25.
//

import SwiftUI

// This view is used to display an history of the saved QR code. QR code are saved on the device nd on iCloud. The user will have filters, but by default we display the QR Code from the latest to the older.
// Let's make sure we use Lazy loading as there can be a lot of QR codes...
// Let's make sure we can use this view with MapView
// We have QRCodeDetailsView to display the details of a QR Code.

struct HistoryView: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    HistoryView()
}
