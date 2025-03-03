//
//  ExchangeRate.swift
//  CurrEx
//

import Foundation

// MARK: - Data Models
struct ExchangeRateResponse: Codable {
    let Bestobmin: [BankRate]
    let PrivatBank: [BankRate]
    let Raiffeisen: [BankRate]
    let timestamp: String
}

struct BankRate: Codable {
    let base_currency: String
    let currency: String
    let rate_buy: String
    let rate_sell: String
}

// MARK: - View Models
struct BankRateViewModel: Identifiable {
    let id = UUID()
    let name: String
    let buyRate: Double
    let sellRate: Double
    let timestamp: String
    
    var spread: Double {
        return sellRate - buyRate
    }
}
