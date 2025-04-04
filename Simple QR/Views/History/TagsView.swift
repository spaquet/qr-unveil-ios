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
                .fill(ColorUtility.color(from: tag.color ?? "#CCCCCC"))
                .frame(width: 16, height: 16)
            
            Text(tag.name)
            
            Spacer()
            
            Text("\(tag.qrCodes?.count ?? 0)")
                .foregroundColor(.secondary)
        }
    }
}

struct TagChipView: View {
    let tag: TagModel
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(ColorUtility.color(from: tag.color ?? "#CCCCCC"))
                .frame(width: 8, height: 8)
            
            Text(tag.name)
                .font(.subheadline)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(ColorUtility.color(from: tag.color ?? "#CCCCCC").opacity(0.15))
        )
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

struct TagPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTags: [TagModel]
    @Query private var availableTags: [TagModel]
    
    var body: some View {
        NavigationStack {
            List {
                if availableTags.isEmpty {
                    ContentUnavailableView {
                        Label("No Tags", systemImage: "tag.slash")
                    } description: {
                        Text("You haven't created any tags yet.")
                    } actions: {
                        Button("Create Tag") {
                            // Add tag creation logic
                        }
                    }
                } else {
                    ForEach(availableTags) { tag in
                        Button {
                            toggleTag(tag)
                        } label: {
                            HStack {
                                Circle()
                                    .fill(ColorUtility.color(from: tag.color ?? "#CCCCCC"))
                                    .frame(width: 16, height: 16)
                                
                                Text(tag.name)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                if selectedTags.contains(where: { $0.id == tag.id }) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Tags")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func toggleTag(_ tag: TagModel) {
        if let index = selectedTags.firstIndex(where: { $0.id == tag.id }) {
            selectedTags.remove(at: index)
        } else {
            selectedTags.append(tag)
        }
    }
}
