//
//  CurrencyType.swift
//  CurrEx
//

import Foundation

// MARK: - Currency Type
enum CurrencyType: String, CaseIterable, Identifiable {
    case usd = "USD"
    case eur = "EUR"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .usd: return "USD"
        case .eur: return "EUR"
        }
    }
}
