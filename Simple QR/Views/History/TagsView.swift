//
//  TagsView.swift
//  Simple QR
//
//  Created by Stéphane PAQUET on 4/3/25.
//

import SwiftData
import SwiftUI

// Tags view placeholder
struct TagsView: View {
    @Query var tags: [TagModel]
    
    var body: some View {
        List {
            ForEach(tags) { tag in
                NavigationLink(destination: TagDetailView(tag: tag)) {
                    TagRowView(tag: tag)
                }
            }
        }
        .navigationTitle("Tags")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    // Add new tag action
                }) {
                    Image(systemName: "plus")
                }
            }
        }
    }
}

// Tag row for list display
struct TagRowView: View {
    let tag: TagModel
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color(tag.color ?? "#CCCCCC"))
                .frame(width: 16, height: 16)
            
            Text(tag.name)
            
            Spacer()
            
            Text("\(tag.qrCodes?.count ?? 0)")
                .foregroundColor(.secondary)
        }
    }
}

// Tag detail view placeholder
struct TagDetailView: View {
    let tag: TagModel
    
    var body: some View {
        Group {
            if let qrCodes = tag.qrCodes, !qrCodes.isEmpty {
                List(qrCodes) { qrCode in
                    NavigationLink(destination: QRDetailView(qrCode: qrCode)) {
                        QRCodeRowView(qrCode: qrCode)
                    }
                }
            } else {
                ContentUnavailableView {
                    Label("No QR Codes", systemImage: "qrcode")
                } description: {
                    Text("No QR codes with this tag yet.")
                } actions: {
                    Button("Scan a QR Code") {
                        // Action to scan a new QR code
                    }
                }
            }
        }
        .navigationTitle(tag.name)
    }
}
