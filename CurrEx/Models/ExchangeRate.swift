//
//  ExchangeRate.swift
//  CurrEx
//
//  Created for CurrEx on 05.03.2025.
//

import Foundation

// MARK: - Data Models
/// Response from exchange rate API
struct ExchangeRateResponse: Codable {
    let Bestobmin: [BankRate]
    let PrivatBank: [BankRate]
    let Raiffeisen: [BankRate]
    let timestamp: String
}

/// Individual bank rate data
struct BankRate: Codable {
    let base_currency: String
    let currency: String
    let rate_buy: String
    let rate_sell: String
}

// MARK: - View Models
/// View model for displaying bank exchange rates
struct BankRateViewModel: Identifiable {
    let id = UUID()
    let name: String
    let buyRate: Double
    let sellRate: Double
    let timestamp: String
    
    /// Difference between sell and buy rates
    var spread: Double {
        return sellRate - buyRate
    }
    
    /// Spread as a percentage of buy rate
    var spreadPercentage: Double {
        guard buyRate > 0 else { return 0 }
        return (spread / buyRate) * 100
    }
    
    /// Formatted buy rate string
    var formattedBuyRate: String {
        return Formatters.formatCurrency(buyRate)
    }
    
    /// Formatted sell rate string
    var formattedSellRate: String {
        return Formatters.formatCurrency(sellRate)
    }
    
    /// Formatted spread string
    var formattedSpread: String {
        return String(format: "%.2f", spread)
    }
    
    /// Formatted timestamp string
    var formattedTimestamp: String {
        return Formatters.formatServerTimestamp(timestamp)
    }
}
