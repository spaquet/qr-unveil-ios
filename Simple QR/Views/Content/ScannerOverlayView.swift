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
                
                // Scanner frame with corner accents
                VStack(spacing: 0) {
                    // Top row of corner indicators
                    HStack(spacing: 0) {
                        CornerIndicator(direction: .topLeading)
                        Spacer()
                        CornerIndicator(direction: .topTrailing)
                    }
                    
                    Spacer()
                    
                    // Bottom row of corner indicators
                    HStack(spacing: 0) {
                        CornerIndicator(direction: .bottomLeading)
                        Spacer()
                        CornerIndicator(direction: .bottomTrailing)
                    }
                }
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
    
    /// Corner indicator for the scanner frame
    struct CornerIndicator: View {
        enum Direction {
            case topLeading, topTrailing, bottomLeading, bottomTrailing
        }
        
        let direction: Direction
        @State private var glowing = false
        
        private let cornerWidth: CGFloat = 30
        private let cornerThickness: CGFloat = 3.5
        
        var body: some View {
            ZStack {
                // Base corner
                CornerShape(direction: direction)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [.white, Color.green.opacity(0.7)]),
                            startPoint: startPoint,
                            endPoint: endPoint
                        ),
                        style: StrokeStyle(lineWidth: cornerThickness, lineCap: .round, lineJoin: .round)
                    )
                    .frame(width: cornerWidth, height: cornerWidth)
                
                // Glow effect
                CornerShape(direction: direction)
                    .stroke(
                        Color.green,
                        style: StrokeStyle(lineWidth: cornerThickness - 1, lineCap: .round, lineJoin: .round)
                    )
                    .blur(radius: glowing ? 3 : 1)
                    .opacity(glowing ? 0.7 : 0.3)
                    .frame(width: cornerWidth, height: cornerWidth)
                    .animation(
                        Animation.easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(directionIndex) * 0.3),
                        value: glowing
                    )
            }
            .onAppear {
                glowing = true
            }
        }
        
        // Helper to determine animation sequence
        private var directionIndex: Int {
            switch direction {
            case .topLeading: return 0
            case .topTrailing: return 1
            case .bottomTrailing: return 2
            case .bottomLeading: return 3
            }
        }
        
        // Gradient direction
        private var startPoint: UnitPoint {
            switch direction {
            case .topLeading: return .bottomTrailing
            case .topTrailing: return .bottomLeading
            case .bottomLeading: return .topTrailing
            case .bottomTrailing: return .topLeading
            }
        }
        
        private var endPoint: UnitPoint {
            switch direction {
            case .topLeading: return .topLeading
            case .topTrailing: return .topTrailing
            case .bottomLeading: return .bottomLeading
            case .bottomTrailing: return .bottomTrailing
            }
        }
    }
    
    /// Custom shape for the corner indicators
    struct CornerShape: Shape {
        let direction: CornerIndicator.Direction
        
        func path(in rect: CGRect) -> Path {
            var path = Path()
            
            switch direction {
            case .topLeading:
                path.move(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.4))
                path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
                path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.4, y: rect.minY))
                
            case .topTrailing:
                path.move(to: CGPoint(x: rect.maxX - rect.width * 0.4, y: rect.minY))
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.4))
                
            case .bottomLeading:
                path.move(to: CGPoint(x: rect.minX, y: rect.maxY - rect.height * 0.4))
                path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
                path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.4, y: rect.maxY))
                
            case .bottomTrailing:
                path.move(to: CGPoint(x: rect.maxX - rect.width * 0.4, y: rect.maxY))
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - rect.height * 0.4))
            }
            
            return path
        }
    }
}

#Preview {
    ZStack {
        Color.black
        ScannerOverlayView()
    }
}
