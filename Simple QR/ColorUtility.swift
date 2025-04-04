//
//  ColorUtility.swift
//  QR Unveil
//
//  Created on 4/4/25.
//

import SwiftUI

/// Utility class for color-related functions used throughout the app
enum ColorUtility {
    /// Converts a hex string to a SwiftUI Color
    /// - Parameter hex: A hex color string (e.g., "#FF5733", "FF5733", "F53", "#F53")
    /// - Returns: A SwiftUI Color object
    static func color(from hex: String) -> Color {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 204, 204, 204) // Default to a light gray
        }

        return Color(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    /// Returns a darker shade of the given color
    /// - Parameters:
    ///   - color: The base color
    ///   - percentage: How much darker to make the color (0.0-1.0)
    /// - Returns: A darker version of the color
    static func darker(_ color: Color, by percentage: CGFloat = 0.2) -> Color {
        let uiColor = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        return Color(
            .sRGB,
            red: max(r - percentage, 0),
            green: max(g - percentage, 0),
            blue: max(b - percentage, 0),
            opacity: a
        )
    }
    
    /// Returns a lighter shade of the given color
    /// - Parameters:
    ///   - color: The base color
    ///   - percentage: How much lighter to make the color (0.0-1.0)
    /// - Returns: A lighter version of the color
    static func lighter(_ color: Color, by percentage: CGFloat = 0.2) -> Color {
        let uiColor = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        return Color(
            .sRGB,
            red: min(r + percentage, 1),
            green: min(g + percentage, 1),
            blue: min(b + percentage, 1),
            opacity: a
        )
    }
    
    /// Determines if a color is "dark" (needs white text) or "light" (needs black text)
    /// - Parameter color: The color to evaluate
    /// - Returns: True if the color is dark
    static func isDark(_ color: Color) -> Bool {
        let uiColor = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        // Calculate relative luminance
        let luminance = 0.299 * r + 0.587 * g + 0.114 * b
        
        return luminance < 0.5
    }
    
    /// Returns an appropriate text color (black or white) based on background color
    /// - Parameter backgroundColor: The background color
    /// - Returns: White for dark backgrounds, black for light backgrounds
    static func appropriateTextColor(for backgroundColor: Color) -> Color {
        return isDark(backgroundColor) ? .white : .black
    }
    
    /// Returns a random color from a predefined set of aesthetic colors
    /// - Returns: A random color
    static func randomColor() -> Color {
        let colors: [Color] = [
            Color.blue,
            Color.indigo,
            Color.purple,
            Color.pink,
            Color.red,
            Color.orange,
            Color.yellow,
            Color.green,
            Color.mint,
            Color.teal,
            Color.cyan
        ]
        
        return colors.randomElement() ?? .blue
    }
    
    /// Returns a random color as a hex string
    /// - Returns: A random color hex string (with # prefix)
    static func randomHexColor() -> String {
        let colors = [
            "#FF5733", // Red-Orange
            "#33FF57", // Green
            "#3357FF", // Blue
            "#FF33A8", // Pink
            "#33FFF0", // Cyan
            "#F033FF", // Magenta
            "#FF8333", // Orange
            "#33FF83", // Mint
            "#8333FF", // Purple
            "#FFCE33", // Yellow
            "#33B5FF", // Light Blue
            "#FF33B5"  // Rose
        ]
        
        return colors[Int.random(in: 0..<colors.count)]
    }
}
