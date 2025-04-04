//
//  QRDetailHeaderSection.swift
//  Simple QR
//
//  Created by Stéphane PAQUET on 4/3/25.
//

import MessageUI
import SwiftData
import SwiftUI

// MARK: - Header Section
struct QRDetailHeaderSection: View {
    let qrCode: QRCodeModel
    @Binding var isEditing: Bool
    @Binding var editedLabel: String
    let modelContext: ModelContext
    
    // Add these state properties to track button presses
    @State private var isCopyPressed = false
    @State private var isSharePressed = false
    @State private var showShareSheet = false  // New state for share sheet
    @State private var isFavoritePressed = false
    
    // Display the picture of the QR code if it exits
    @State private var qrCodeImage: UIImage?
    @State private var isLoadingImage: Bool = false
    
    var body: some View {
        Section {
            VStack(alignment: .center, spacing: 20) {
                // QR Code image
                Group {
                    if isLoadingImage {
                        ProgressView()
                            .frame(width: 200, height: 200)
                    } else if let image = qrCodeImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 200, height: 200)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    } else {
                        // Default QR code icon if no image is available
                        Image(systemName: "qrcode")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 200, height: 200)
                            .padding()
                            .background(Color.clear)
                    }
                }
                .padding(.vertical, 10)
                
                // Label/Title - Enhanced with better editing experience
                if isEditing {
                    TextField("Label", text: $editedLabel)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color(UIColor.tertiarySystemBackground))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                } else {
                    Text(qrCode.label ?? qrCode.formattedContent())
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .background(Color.clear) // Ensure background is clear
                }
                
                // Action buttons - Complete redesign with improved touch targets
                HStack(spacing: 0) {
                    // Each button is in its own container with clear boundaries
                    Spacer()
                    
                    // Copy Button
                    VStack {
                        Button {
                            UIPasteboard.general.string = qrCode.content
                            // Visual feedback
                            withAnimation {
                                isCopyPressed = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                withAnimation {
                                    isCopyPressed = false
                                }
                            }
                        } label: {
                            VStack {
                                Image(systemName: "doc.on.doc")
                                    .font(.title2)
                                    .foregroundColor(isCopyPressed ? .blue : .primary)
                                
                                Text("Copy")
                                    .font(.caption)
                                    .foregroundColor(.primary)
                            }
                            .frame(width: 80, height: 60)
                            .contentShape(Rectangle()) // Important for proper hit testing
                        }
                        .buttonStyle(BorderlessButtonStyle()) // Prevents tap propagation
                        .disabled(isEditing) // Disable when editing
                        .opacity(isEditing ? 0.5 : 1.0) // Visual indicator when disabled
                    }
                    .padding(.horizontal, 5)
                    .background(Color.clear)
                    
                    Spacer()
                    
                    // Share Button
                    VStack {
                        Button {
                            // Trigger share sheet
                            withAnimation {
                                isSharePressed = true
                            }
                            showShareSheet = true
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                withAnimation {
                                    isSharePressed = false
                                }
                            }
                        } label: {
                            VStack {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.title2)
                                    .foregroundColor(isSharePressed ? .blue : .primary)
                                
                                Text("Share")
                                    .font(.caption)
                                    .foregroundColor(.primary)
                            }
                            .frame(width: 80, height: 60)
                            .contentShape(Rectangle()) // Important for proper hit testing
                        }
                        .buttonStyle(BorderlessButtonStyle()) // Prevents tap propagation
                        .disabled(isEditing) // Disable when editing
                        .opacity(isEditing ? 0.5 : 1.0) // Visual indicator when disabled
                    }
                    .padding(.horizontal, 5)
                    .background(Color.clear)
                    
                    Spacer()
                    
                    // Favorite Button
                    VStack {
                        Button {
                            qrCode.toggleFavorite()
                            do {
                                try modelContext.save()
                            } catch {
                                print("Error toggling favorite: \(error)")
                            }
                            // Visual feedback
                            withAnimation {
                                isFavoritePressed = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                withAnimation {
                                    isFavoritePressed = false
                                }
                            }
                        } label: {
                            VStack {
                                Image(systemName: qrCode.isFavorite ? "star.fill" : "star")
                                    .font(.title2)
                                    .foregroundColor(qrCode.isFavorite ? .yellow : (isFavoritePressed ? .blue : .gray))
                                
                                Text("Favorite")
                                    .font(.caption)
                                    .foregroundColor(.primary)
                            }
                            .frame(width: 80, height: 60)
                            .contentShape(Rectangle()) // Important for proper hit testing
                        }
                        .buttonStyle(BorderlessButtonStyle()) // Prevents tap propagation
                        .disabled(isEditing) // Disable when editing
                        .opacity(isEditing ? 0.5 : 1.0) // Visual indicator when disabled
                    }
                    .padding(.horizontal, 5)
                    .background(Color.clear)
                    
                    Spacer()
                }
                .padding(.top, 10)
                .background(Color.clear) // Ensure background is clear
            }
            .frame(maxWidth: .infinity)
            .listRowInsets(EdgeInsets()) // Removes default list row padding
            .background(Color.clear) // Ensure background is clear for the entire section
            .shareSheet(isPresented: $showShareSheet, items: [
                qrCode.content,
                "Check out this QR code I scanned with QR Unveil! Get the app at https://qrunveil.pages.dev"
            ])
            .onAppear {
                loadQRCodeImage()
            }
        }
    }
    
    private func loadQRCodeImage() {
        // Check if we have a photo asset ID
        guard let assetId = qrCode.photoAssetId, !isLoadingImage else {
            return
        }
        
        isLoadingImage = true
        
        PhotoManager.shared.fetchQRCodeImage(assetId: assetId) { image in
            self.qrCodeImage = image
            self.isLoadingImage = false
        }
    }
}

// MARK: - Info Section
struct QRDetailInfoSection: View {
    let qrCode: QRCodeModel
    
    var body: some View {
        Section("Details") {
            LabeledContent("Type", value: qrCode.qrType.capitalized)
            LabeledContent("Created", value: formattedDate(qrCode.createdAt))
            LabeledContent("Last Scanned", value: qrCode.lastScanned != nil ? formattedDate(qrCode.lastScanned!) : "N/A")
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Content Section
struct QRDetailContentSection: View {
    let content: String
    let qrType: String
    
    var body: some View {
        Section("Content") {
            ActionableQRContentView(content: content, type: qrType)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
        }
    }
}

// MARK: - Location Section
struct QRDetailLocationSection: View {
    let location: LocationModel
    @State private var isCopyPressed = false
    
    var body: some View {
        Section("Location") {
            LabeledContent("Name", value: location.name)
            
            // Formatted coordinates (shorter display)
            HStack {
                Text("Coordinates")
                Spacer()
                Text("\(formattedCoordinates(latitude: location.latitude, longitude: location.longitude))")
                
                // Copy button for full precision coordinates
                Button {
                    // Copy full precision coordinates to clipboard
                    UIPasteboard.general.string = "\(location.latitude), \(location.longitude)"
                    
                    // Visual feedback
                    withAnimation {
                        isCopyPressed = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation {
                            isCopyPressed = false
                        }
                    }
                } label: {
                    Image(systemName: isCopyPressed ? "doc.on.doc.fill" : "doc.on.doc")
                        .foregroundColor(isCopyPressed ? .blue : .gray)
                        .font(.footnote)
                }
                .buttonStyle(BorderlessButtonStyle())
                .padding(.leading, 4)
            }
            
            if let address = location.address {
                LabeledContent("Address", value: address)
            }
            
            // Map view with interactions disabled
            NonInteractiveMapLocationView(latitude: location.latitude, longitude: location.longitude)
                .frame(height: 180)
                .cornerRadius(8)
                .padding(.vertical, 4)
        }
    }
    
    // Format coordinates to show fewer decimal places
    private func formattedCoordinates(latitude: Double, longitude: Double) -> String {
        // Format to 5 decimal places (approx. 1 meter precision)
        return String(format: "%.5f, %.5f", latitude, longitude)
    }
}

// MARK: - Tags Section
struct QRDetailTagsSection: View {
    let tags: [TagModel]
    
    var body: some View {
        Section("Tags") {
            if tags.isEmpty {
                Text("No tags")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(tags) { tag in
                            TagChipView(tag: tag)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
}

// MARK: - Helper Components

// Action button component
struct ActionButton: View {
    let icon: String
    let label: String
    var iconColor: Color = .primary
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(iconColor)
                Text(label)
                    .font(.caption)
            }
        }
    }
}

// Tag view component
struct TagView: View {
    let tag: TagModel
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color(tag.color ?? "#CCCCCC"))
                .frame(width: 8, height: 8)
            Text(tag.name)
                .font(.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}


// Extension to create a Share Sheet in SwiftUI
extension View {
    func shareSheet(isPresented: Binding<Bool>, items: [Any]) -> some View {
        self.modifier(ShareSheetModifier(isPresented: isPresented, items: items))
    }
}

// Share Sheet Modifier
struct ShareSheetModifier: ViewModifier {
    @Binding var isPresented: Bool
    let items: [Any]
    
    func body(content: Content) -> some View {
        content
            .background(
                ShareSheetRepresentable(isPresented: $isPresented, items: items)
                    .opacity(0)
            )
    }
}

// UIViewControllerRepresentable for Share Sheet
struct ShareSheetRepresentable: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if isPresented {
            let activityVC = UIActivityViewController(
                activityItems: items,
                applicationActivities: nil
            )
            
            // Prevent crash on iPad
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = uiViewController.view
                popover.sourceRect = CGRect(x: uiViewController.view.bounds.midX,
                                          y: uiViewController.view.bounds.midY,
                                          width: 0,
                                          height: 0)
                popover.permittedArrowDirections = []
            }
            
            activityVC.completionWithItemsHandler = { _, _, _, _ in
                self.isPresented = false
            }
            
            uiViewController.present(activityVC, animated: true)
        }
    }
}
