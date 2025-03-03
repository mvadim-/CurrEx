//
//  Formatters.swift
//  CurrEx
//

import Foundation

// MARK: - Utility Formatters
struct Formatters {
    // Date formatter configured for Ukrainian locale
    static let ukrainianDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "uk_UA")
        return formatter
    }()
    
    // ISO formatter for server timestamps
    static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    // Currency formatter
    static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    // Format currency value with UAH symbol
    static func formatCurrency(_ value: Double) -> String {
        return "\(currencyFormatter.string(from: NSNumber(value: value)) ?? "0.00") ₴"
    }
    
    // Format server timestamp to user-friendly string
    static func formatServerTimestamp(_ isoString: String) -> String {
        guard let date = isoFormatter.date(from: isoString) else {
            return "Не вказано"
        }
        return ukrainianDateFormatter.string(from: date)
    }
}
