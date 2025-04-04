//
//  HistoryView.swift
//  QR Unveil
//
//  Created by Stéphane PAQUET on 4/2/25.
//

import SwiftData
import SwiftUI

// This view is used to display an history of the saved QR code. QR code are saved on the device nd on iCloud. The user will have filters, but by default we display the QR Code from the latest to the older.
// Let's make sure we use Lazy loading as there can be a lot of QR codes...
// Let's make sure we can use this view with MapView
// We have QRCodeDetailsView to display the details of a QR Code.

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \QRCodeModel.createdAt, order: .reverse) var qrCodes: [QRCodeModel]
    
    @State private var searchText = ""
    @State private var showingFilterOptions = false
    @State private var selectedFilter: QRFilter = .all
    
    enum QRFilter {
        case all
        case favorites
        case urls
        case contacts
        case wifi
        case text
    }
    
    var filteredQRCodes: [QRCodeModel] {
        if searchText.isEmpty {
            switch selectedFilter {
            case .all:
                return qrCodes
            case .favorites:
                return qrCodes.filter { $0.isFavorite }
            case .urls:
                return qrCodes.filter { $0.qrType == "url" }
            case .contacts:
                return qrCodes.filter { $0.qrType == "vcard" }
            case .wifi:
                return qrCodes.filter { $0.qrType == "wifi" }
            case .text:
                return qrCodes.filter { $0.qrType == "text" }
            }
        } else {
            return qrCodes.filter {
                $0.content.localizedCaseInsensitiveContains(searchText) ||
                ($0.label?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    var body: some View {
        List {
            if filteredQRCodes.isEmpty {
                ContentUnavailableView {
                    Label("No QR Codes", systemImage: "qrcode")
                } description: {
                    Text("Scan a QR code to add it to your history.")
                }
            } else {
                ForEach(filteredQRCodes) { qrCode in
                    NavigationLink(destination: QRDetailView(qrCode: qrCode)) {
                        QRCodeRowView(qrCode: qrCode)
                    }
                }
                .onDelete(perform: deleteQRCodes)
            }
        }
        .navigationTitle("History")
        .searchable(text: $searchText, prompt: "Search QR codes")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Picker("Filter", selection: $selectedFilter) {
                        Label("All", systemImage: "qrcode").tag(QRFilter.all)
                        Label("Favorites", systemImage: "star.fill").tag(QRFilter.favorites)
                        Label("URLs", systemImage: "link").tag(QRFilter.urls)
                        Label("Contacts", systemImage: "person.fill").tag(QRFilter.contacts)
                        Label("WiFi", systemImage: "wifi").tag(QRFilter.wifi)
                        Label("Text", systemImage: "text.alignleft").tag(QRFilter.text)
                    }
                } label: {
                    Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                }
            }
        }
    }
    
    private func deleteQRCodes(offsets: IndexSet) {
        for index in offsets {
            let qrCodeToDelete = filteredQRCodes[index]
            modelContext.delete(qrCodeToDelete)
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Error deleting QR code: \(error.localizedDescription)")
        }
    }
}
