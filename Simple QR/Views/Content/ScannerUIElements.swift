//
//  ScannerUIElements.swift
//  QR Unveil
//
//  Created on 4/7/25.
//

import SwiftUI
import AVFoundation

/// UI elements displayed on top of the camera view
struct ScannerUIElements: View {
    @Binding var navigationPath: NavigationPath
    @ObservedObject var cameraManager: CameraManager
    
    var body: some View {
        VStack {
            // Top bar
            HStack {
                Text("QR Unveil")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .shadow(radius: 2)
                
                Spacer()
                
                // Menu button
                Menu {
                    ForEach(NavDestination.allCases) { destination in
                        Button {
                            navigationPath.append(destination)
                        } label: {
                            Label(destination.title, systemImage: destination.icon)
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                        .shadow(radius: 2)
                }
            }
            .padding()
            
            // Instruction text above the frame
            Text("Position QR code within frame")
                .font(.subheadline)
                .foregroundColor(.white)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(Color.black.opacity(0.6))
                .cornerRadius(10)
                .padding(.top, 20)
            
            Spacer()
            
            // Bottom bar with camera controls
            HStack {
                Spacer()
                
                // Flash button
                Button {
                    cameraManager.toggleTorch()
                } label: {
                    Image(systemName: cameraManager.isTorchOn ? "bolt.fill" : "bolt.slash")
                        .font(.title2)
                        .foregroundColor(cameraManager.isTorchOn ? .yellow : .white)
                        .padding(15)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                }
                
                Spacer()
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 40)
        }
    }
}

#Preview {
    ZStack {
        Color.black
        ScannerUIElements(
            navigationPath: .constant(NavigationPath()),
            cameraManager: CameraManager()
        )
    }
}
