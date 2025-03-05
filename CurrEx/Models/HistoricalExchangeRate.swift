//
//  HistoricalExchangeRate.swift
//  CurrEx
//
//  Created for CurrEx on 05.03.2025.
//

import Foundation

// MARK: - Period Type
/// Available time periods for historical data
enum PeriodType: Int, CaseIterable, Identifiable {
    case day1 = 1
    case day3 = 3
    case day7 = 7
    case day30 = 30
    case day90 = 90
    case day180 = 180
    case day360 = 360
    
    var id: Int { self.rawValue }
    
    /// User-facing display name
    var displayName: String {
        switch self {
        case .day1: return NSLocalizedString("1 day", comment: "1 day period")
        case .day3: return NSLocalizedString("3 days", comment: "3 days period")
        case .day7: return NSLocalizedString("7 days", comment: "7 days period")
        case .day30: return NSLocalizedString("30 days", comment: "30 days period")
        case .day90: return NSLocalizedString("90 days", comment: "90 days period")
        case .day180: return NSLocalizedString("180 days", comment: "180 days period")
        case .day360: return NSLocalizedString("360 days", comment: "360 days period")
        }
    }
}

// MARK: - Data Models
/// Response from historical exchange rate API
struct HistoricalExchangeRateResponse: Codable {
    let currency: String
    let data: [HistoricalDataPoint]
    let period_days: Int
}

/// Individual data point in the historical data
struct HistoricalDataPoint: Codable {
    let rates: RatesData
    let timestamp: String
}

/// Rates for different banks
struct RatesData: Codable {
    let Bestobmin: [BankRate]?
    let PrivatBank: [BankRate]?
    let Raiffeisen: [BankRate]?
}

// MARK: - View Models
/// View model for displaying historical rate data points
struct HistoricalRateDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let bankRates: [String: (buy: Double, sell: Double)]
    
    /// Gets the buy rate for a specific bank
    /// - Parameter bank: Bank name
    /// - Returns: Buy rate or 0 if data is not available
    func getBuyRate(for bank: String) -> Double {
        return bankRates[bank]?.buy ?? 0
    }
    
    /// Gets the sell rate for a specific bank
    /// - Parameter bank: Bank name
    /// - Returns: Sell rate or 0 if data is not available
    func getSellRate(for bank: String) -> Double {
        return bankRates[bank]?.sell ?? 0
    }
    
    /// Gets the formatted date string
    var formattedDate: String {
        return Formatters.formatChartDate(date)
    }
    
    /// Gets the full formatted date and time string
    var formattedDateTime: String {
        return Formatters.ukrainianDateFormatter.string(from: date)
    }
}
