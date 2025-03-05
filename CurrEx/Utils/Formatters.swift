//
//  Formatters.swift
//  CurrEx
//
//  Created for CurrEx on 05.03.2025.
//

import Foundation

// MARK: - Utility Formatters
/// Provides centralized date and number formatting capabilities
struct Formatters {
    /// Date formatter configured for Ukrainian locale
    static let ukrainianDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "uk_UA")
        return formatter
    }()
    
    /// ISO formatter for server timestamps
    static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    /// Currency formatter
    static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    /// Currency formatter with additional options
    static func configurableCurrencyFormatter(
        minFractionDigits: Int = 2,
        maxFractionDigits: Int = 2
    ) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = minFractionDigits
        formatter.maximumFractionDigits = maxFractionDigits
        return formatter
    }
    
    /// Format currency value with UAH symbol
    /// - Parameter value: Currency value to format
    /// - Returns: Formatted string with currency symbol
    static func formatCurrency(_ value: Double) -> String {
        return "\(currencyFormatter.string(from: NSNumber(value: value)) ?? "0.00") ₴"
    }
    
    /// Format server timestamp to user-friendly string
    /// - Parameter isoString: ISO 8601 timestamp from server
    /// - Returns: Formatted date and time string
    static func formatServerTimestamp(_ isoString: String) -> String {
        guard let date = isoFormatter.date(from: isoString) else {
            return NSLocalizedString("Not specified", comment: "Timestamp not available")
        }
        return ukrainianDateFormatter.string(from: date)
    }
    
    /// Format current date and time
    /// - Returns: Formatted current date and time string
    static func formatCurrentDateTime() -> String {
        return ukrainianDateFormatter.string(from: Date())
    }
    
    /// Format date for use in charts
    /// - Parameter date: Date to format
    /// - Returns: Formatted date string
    static func formatChartDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM"
        return formatter.string(from: date)
    }
}
