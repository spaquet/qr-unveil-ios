//
//  PhotoPermissionView.swift
//  Simple QR
//
//  Created by Stéphane PAQUET on 4/4/25.
//


import SwiftUI
import Photos

struct PhotoPermissionView: View {
    var onAllow: () -> Void
    var onDeny: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            // Photo library icon with styled appearance
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 110, height: 110)
                
                Circle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 90, height: 90)
                
                Image(systemName: "photo.stack.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
            }
            .shadow(color: Color.blue.opacity(0.5), radius: 10, x: 0, y: 0)
            .padding(.top, 20)
            
            // Title and description
            Text("Photo Library Access")
                .font(.system(size: 24, weight: .bold, design: .rounded))
            
            VStack(spacing: 16) {
                Text("Save Your QR Code")
                    .font(.title3)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                
                Text("QR Unveil needs full access to your photo library to save QR code images and display them later. Without this permission, you won't be able to see your saved QR codes within the app.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
            .padding(.horizontal, 20)
            
            Spacer(minLength: 20)
            
            // Buttons with similar styling to the location view
            VStack(spacing: 16) {
                Button {
                    onAllow()
                } label: {
                    Text("Allow Full Photo Access")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 3)
                }
                .padding(.horizontal, 30)
                
                Button {
                    onDeny()
                } label: {
                    Text("Continue Without Saving Image")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.bottom, 30)
        }
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .padding()
    }
}

// Usage in ContentView:
// Replace your existing photoPermissionView with this:
/*
var photoPermissionView: some View {
    PhotoPermissionView(
        onAllow: {
            // Request photo library permission
            PhotoManager.shared.requestPhotoLibraryAccess { success in
                if success {
                    // If permission granted, save the image
                    if let capturedImage = cameraManager.capturedImage {
                        saveQRCodeWithImage(capturedImage)
                    }
                } else {
                    // User denied, proceed without image
                    saveQRCodeWithoutImage()
                }
                showPhotoPermission = false
            }
        },
        onDeny: {
            // Proceed without saving image
            saveQRCodeWithoutImage()
            showPhotoPermission = false
        }
    )
}
*/

#Preview {
    PhotoPermissionView(
        onAllow: {},
        onDeny: {}
    )
}
