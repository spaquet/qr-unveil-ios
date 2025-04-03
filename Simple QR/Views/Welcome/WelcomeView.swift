//
//  WelcomeView.swift
//  QR Unveil
//
//  Created by Stéphane PAQUET on 4/3/25.
//

import SwiftUI

struct WelcomeView: View {
    // Callback to notify parent controller to proceed to next step
    var proceedToNextStep: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // Gradient background with animated elements
            BackgroundView()
            
            VStack(spacing: 30) {
                // Logo and app name
                VStack(spacing: 20) {
                    // App icon with glowing effect
                    ZStack {
                        Circle()
                            .fill(Color.accentColor.opacity(0.15))
                            .frame(width: 130, height: 130)
                        
                        Circle()
                            .fill(Color.accentColor.opacity(0.3))
                            .frame(width: 110, height: 110)
                        
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 60))
                            .foregroundColor(.accentColor)
                    }
                    .shadow(color: Color.accentColor.opacity(0.5), radius: 15, x: 0, y: 0)
                    
                    Text("Welcome to QR Unveil")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 60)
                
                // Features description - with card background
                VStack(alignment: .leading, spacing: 16) {
                    FeatureRow(
                        icon: "qrcode",
                        title: "Scan Any QR Code",
                        description: "Quickly scan QR codes to reveal their raw values"
                    )
                    
                    FeatureRow(
                        icon: "doc.text.magnifyingglass",
                        title: "Identify Type",
                        description: "Automatically detects the type of content in the QR code"
                    )
                    
                    FeatureRow(
                        icon: "arrow.up.doc",
                        title: "Copy & Share",
                        description: "Easily copy the content or open it in other apps"
                    )
                    
                    FeatureRow(
                        icon: "clock.arrow.circlepath",
                        title: "Save History",
                        description: "Keep track of your scanned codes for future reference"
                    )
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(colorScheme == .dark ?
                            Color.black.opacity(0.3) :
                            Color.white.opacity(0.7))
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                )
                .padding(.horizontal, 25)
                
                Spacer()
                
                // Continue button with animation
                Button {
                    // Proceed to the next step in onboarding
                    proceedToNextStep()
                } label: {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.accentColor, Color.accentColor.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: Color.accentColor.opacity(0.3), radius: 5, x: 0, y: 3)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
            }
        }
    }
}

// Helper view for feature rows
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    @Environment(\.colorScheme) private var colorScheme
    @State private var isAnimating = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            // Icon with dynamic background
            ZStack {
                Circle()
                    .fill(colorScheme == .dark ?
                          Color.accentColor.opacity(0.2) :
                          Color.accentColor.opacity(0.1))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.accentColor)
            }
            .scaleEffect(isAnimating ? 1.05 : 1.0)
            .animation(
                Animation
                    .spring(response: 0.5, dampingFraction: 0.6)
                    .repeatCount(1, autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0.1...0.5)) {
                    isAnimating = true
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(0.9)
            }
        }
        .padding(.vertical, 6)
    }
}

// Beautiful animated background that works in light and dark mode
struct BackgroundView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var animateGradient = false
    
    var body: some View {
        ZStack {
            // Base background color
            Color(colorScheme == .dark ? .black : .white)
                .ignoresSafeArea()
            
            // Dynamic gradient overlay
            LinearGradient(
                gradient: Gradient(colors: [
                    colorScheme == .dark ?
                        Color.accentColor.opacity(0.4) :
                        Color.accentColor.opacity(0.1),
                    colorScheme == .dark ?
                        Color.black.opacity(0.8) :
                        Color.white.opacity(0.8),
                    colorScheme == .dark ?
                        Color.black :
                        Color.white
                ]),
                startPoint: animateGradient ? .topLeading : .topTrailing,
                endPoint: animateGradient ? .bottomTrailing : .bottomLeading
            )
            .ignoresSafeArea()
            .onAppear {
                withAnimation(
                    .linear(duration: 10)
                    .repeatForever(autoreverses: true)) {
                    animateGradient.toggle()
                }
            }
            
            // Decorative QR code patterns
            ZStack {
                // Background QR code elements
                Group {
                    QRPatternView()
                        .position(x: 50, y: 100)
                    
                    QRPatternView()
                        .position(x: UIScreen.main.bounds.width - 70, y: 200)
                    
                    QRPatternView()
                        .position(x: 80, y: UIScreen.main.bounds.height - 150)
                    
                    QRPatternView()
                        .position(x: UIScreen.main.bounds.width - 100, y: UIScreen.main.bounds.height - 100)
                }
                .opacity(colorScheme == .dark ? 0.15 : 0.07)
            }
        }
    }
}

// QR code pattern element
struct QRPatternView: View {
    @State private var rotate = false
    private let size: CGFloat = 60
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.accentColor.opacity(0.6), lineWidth: 2)
                .frame(width: size, height: size)
            
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.accentColor.opacity(0.3))
                .frame(width: size/2.5, height: size/2.5)
                .offset(x: -size/5, y: -size/5)
            
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.accentColor.opacity(0.3))
                .frame(width: size/2.5, height: size/2.5)
                .offset(x: size/5, y: size/5)
            
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.accentColor.opacity(0.3))
                .frame(width: size/2.5, height: size/2.5)
                .offset(x: size/5, y: -size/5)
        }
        .rotationEffect(.degrees(rotate ? 90 : 0))
        .onAppear {
            withAnimation(Animation.linear(duration: 20).repeatForever(autoreverses: true)) {
                rotate.toggle()
            }
        }
    }
}

#Preview("Light Mode") {
    WelcomeView(proceedToNextStep: {})
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    WelcomeView(proceedToNextStep: {})
        .preferredColorScheme(.dark)
}
