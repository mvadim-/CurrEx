//
//  Formatters+Extension.swift
//  CurrEx
//
//  Created for CurrEx on 05.03.2025.
//

import Foundation

// MARK: - Formatters Extension for Localization
extension Formatters {
    /// Updates all formatters to use the specified locale
    /// - Parameter locale: The locale to use for formatting
    static func updateLocale(to locale: Locale) {
        // Update date formatter
        ukrainianDateFormatter.locale = locale
        
        // Update currency formatter
        currencyFormatter.locale = locale
        
        // We don't need to update ISO formatter as it's locale-independent
    }
    
    /// Returns the currency symbol for the current locale
    static var currencySymbol: String {
        return "₴" // Hardcoded for now, can be made dynamic if needed
    }
    
    /// Returns the localized currency format with appropriate symbol
    /// - Parameter value: The numeric value to format
    /// - Returns: Formatted string with localized currency symbol
    static func localizedCurrencyFormat(_ value: Double) -> String {
        return "\(currencyFormatter.string(from: NSNumber(value: value)) ?? "0.00") \(currencySymbol)"
    }
}
