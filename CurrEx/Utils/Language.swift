//
//  Language.swift
//  CurrEx
//
//  Created for CurrEx on 05.03.2025.
//

import Foundation

/// Supported application languages
enum Language: String, CaseIterable, Identifiable {
    case english = "en"
    case ukrainian = "uk"
    
    var id: String { self.rawValue }
    
    /// User-facing display name
    var displayName: String {
        switch self {
        case .english: return NSLocalizedString("English", comment: "English language name")
        case .ukrainian: return NSLocalizedString("Українська", comment: "Ukrainian language name")
        }
    }
    
    /// Locale identifier for the language
    var localeIdentifier: String {
        switch self {
        case .english: return "en_US"
        case .ukrainian: return "uk_UA"
        }
    }
    
    /// Flag emoji for the language
    var flagEmoji: String {
        switch self {
        case .english: return "🇺🇸"
        case .ukrainian: return "🇺🇦"
        }
    }
}
