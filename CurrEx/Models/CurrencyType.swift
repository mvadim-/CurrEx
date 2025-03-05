//
//  CurrencyType.swift
//  CurrEx
//
//  Created for CurrEx on 05.03.2025.
//

import Foundation
import Combine
import SwiftUI

// MARK: - Currency Type
/// Supported currency types in the application
enum CurrencyType: String, CaseIterable, Identifiable {
    case usd = "USD"
    case eur = "EUR"
    
    var id: String { self.rawValue }
    
    /// User-facing display name
    var displayName: String {
        switch self {
        case .usd: return "USD"
        case .eur: return "EUR"
        }
    }
    
    /// Symbol for the currency
    var symbol: String {
        switch self {
        case .usd: return "$"
        case .eur: return "€"
        }
    }
}

// Note: Custom onChange backward compatibility code has been removed
// iOS 14+ has native onChange support, and iOS 17+ uses a new API format
// See ExchangeRateView+iOS17.swift for cross-version compatible implementation
