//
//  ColorScheme.swift
//  CurrEx
//
//  Created for CurrEx on 05.03.2025.
//

import SwiftUI

/// Provides app-wide consistent colors with support for both light and dark modes
enum AppColors {
    static var background: Color {
        Color(.systemBackground)
    }
    
    static var secondaryBackground: Color {
        Color(.secondarySystemBackground)
    }
    
    static var tertiaryBackground: Color {
        Color(.tertiarySystemBackground)
    }
    
    static var groupedBackground: Color {
        Color(.systemGroupedBackground)
    }
    
    static var secondaryGroupedBackground: Color {
        Color(.secondarySystemGroupedBackground)
    }
    
    static var text: Color {
        Color(.label)
    }
    
    static var secondaryText: Color {
        Color(.secondaryLabel)
    }
    
    static var tertiaryText: Color {
        Color(.tertiaryLabel)
    }
    
    static var accentColor: Color {
        Color("AccentColor")
    }
    
    static var sellColor: Color {
        Color("SellColor", bundle: .main)
    }
    
    static var buyColor: Color {
        Color("BuyColor", bundle: .main)
    }
    
    static var dividerColor: Color {
        Color(.separator)
    }
    
    static var cardShadow: Color {
        Color.black.opacity(0.1)
    }
}

/// Card style for consistent appearance across the app
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(AppColors.background)
            .cornerRadius(12)
            .shadow(color: AppColors.cardShadow, radius: 5, x: 0, y: 2)
    }
}

extension View {
    /// Applies consistent card styling across the app
    func cardStyle() -> some View {
        self.modifier(CardStyle())
    }
}
