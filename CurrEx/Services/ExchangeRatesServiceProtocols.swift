//
//  ExchangeRatesServiceProtocols.swift
//  CurrEx
//
//  Created for CurrEx on 05.03.2025.
//

import Foundation

// MARK: - Service Protocols
/// Protocol for current exchange rates service
protocol ExchangeRatesServiceProtocol {
    /// Fetches current exchange rates for specified currency
    /// - Parameter currency: Currency code (e.g. "USD", "EUR")
    /// - Returns: Array of bank rates for the requested currency
    func fetchExchangeRates(for currency: String) async throws -> [BankRateViewModel]
}

/// Protocol for historical exchange rates service
protocol HistoricalExchangeRatesServiceProtocol {
    /// Fetches historical exchange rates for specified currency and period
    /// - Parameters:
    ///   - currency: Currency code (e.g. "USD", "EUR")
    ///   - period: Number of days to look back
    /// - Returns: Array of historical rate data points
    func fetchHistoricalRates(for currency: String, period: Int) async throws -> [HistoricalRateDataPoint]
}

// MARK: - Network Errors
enum NetworkError: Error {
    case invalidConfiguration
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case decodingFailed(Error)
    
    var localizedDescription: String {
        switch self {
        case .invalidConfiguration:
            return NSLocalizedString("Missing or invalid API configuration", comment: "")
        case .invalidURL:
            return NSLocalizedString("Invalid API URL", comment: "")
        case .requestFailed(let error):
            return NSLocalizedString("Network request failed: \(error.localizedDescription)", comment: "")
        case .invalidResponse:
            return NSLocalizedString("Invalid server response", comment: "")
        case .decodingFailed(let error):
            return NSLocalizedString("Failed to parse server response: \(error.localizedDescription)", comment: "")
        }
    }
}
