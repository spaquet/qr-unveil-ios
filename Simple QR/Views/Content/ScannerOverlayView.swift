//
//  ScannerOverlayView.swift
//  Simple QR
//
//  Created by Stéphane PAQUET on 4/7/25.
//

import SwiftUI

/// Overlay view with transparent cutout for scanning area and animation
struct ScannerOverlayView: View {
    // Animation states
    @State private var isAnimating = false
    @State private var cornerRadius: CGFloat = 20
    @State private var scannerOpacity: Double = 0.5
    
    // Constants
    private let scannerSize: CGFloat = 260
    private let cornerWidth: CGFloat = 30
    private let cornerThickness: CGFloat = 3
    private let scanLineHeight: CGFloat = 2
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Semi-transparent black overlay for the entire screen
                Rectangle()
                    .fill(Color.black.opacity(0.6))
                    .edgesIgnoringSafeArea(.all)
                
                // Transparent window in the middle (cut out)
                RoundedRectangle(cornerRadius: cornerRadius)
                    .frame(width: scannerSize, height: scannerSize)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    .blendMode(.destinationOut)
                
                // Add a separate border around the scanner area (optional)
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    .frame(width: scannerSize, height: scannerSize)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                
                // Scanning line animation
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                .clear,
                                Color.green.opacity(0.5),
                                Color.green,
                                Color.green.opacity(0.5),
                                .clear
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: scannerSize - 20, height: scanLineHeight)
                    .position(
                        x: geometry.size.width / 2,
                        y: geometry.size.height / 2 + (isAnimating ? scannerSize / 2 - 10 : -scannerSize / 2 + 10)
                    )
                    .shadow(color: Color.green.opacity(0.5), radius: 5, x: 0, y: 0)
                
                // Status text below the scanner
                Text("Scanning...")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.7))
                    )
                    .position(
                        x: geometry.size.width / 2,
                        y: geometry.size.height / 2 + scannerSize / 2 + 40
                    )
                    .opacity(scannerOpacity)
                    .animation(
                        Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                        value: scannerOpacity
                    )
            }
            .compositingGroup()
            .onAppear {
                // Start all animations when view appears
                withAnimation(
                    Animation.easeInOut(duration: 2)
                        .repeatForever(autoreverses: true)
                ) {
                    isAnimating = true
                }
                
                // Animate the opacity of the status text
                withAnimation(
                    Animation.easeInOut(duration: 1.2)
                        .repeatForever(autoreverses: true)
                ) {
                    scannerOpacity = 0.8
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black
        ScannerOverlayView()
    }
}
