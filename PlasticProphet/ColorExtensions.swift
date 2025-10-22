// ColorExtensions.swift
// Reusable color utilities for PlasticProphet

import SwiftUI

extension Color {
    // Initialize Color from hex string
    init(hex: String) {
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
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    // PlasticProphet brand colors
    static let ppGreen = Color(hex: "2ac33c")
    static let ppShadow = Color(hex: "0a3a0e")
    
    // Network colors
    static let visaBlue = Color(hex: "1434cb")
    static let mastercardRed = Color(hex: "eb001b")
    static let amexBlue = Color(hex: "016fd0")
    static let discoverOrange = Color(hex: "e55c20")
}
