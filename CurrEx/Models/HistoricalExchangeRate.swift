//
//  HistoricalExchangeRate.swift
//  CurrEx
//

import Foundation

// MARK: - Period Type
enum PeriodType: Int, CaseIterable, Identifiable {
    case day1 = 1
    case day3 = 3
    case day7 = 7
    case day30 = 30
    case day90 = 90
    case day180 = 180
    case day360 = 360
    
    var id: Int { self.rawValue }
    
    var displayName: String {
        switch self {
        case .day1: return "1 день"
        case .day3: return "3 дні"
        case .day7: return "7 днів"
        case .day30: return "30 днів"
        case .day90: return "90 днів"
        case .day180: return "180 днів"
        case .day360: return "360 днів"
        }
    }
}

// MARK: - Data Models
struct HistoricalExchangeRateResponse: Codable {
    let currency: String
    let data: [HistoricalDataPoint]
    let period_days: Int
}

struct HistoricalDataPoint: Codable {
    let rates: RatesData
    let timestamp: String
}

struct RatesData: Codable {
    let Bestobmin: [BankRate]?
    let PrivatBank: [BankRate]?
    let Raiffeisen: [BankRate]?
}

// MARK: - View Models
struct HistoricalRateDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let bankRates: [String: (buy: Double, sell: Double)]
    
    func getBuyRate(for bank: String) -> Double {
        return bankRates[bank]?.buy ?? 0
    }
    
    func getSellRate(for bank: String) -> Double {
        return bankRates[bank]?.sell ?? 0
    }
}
