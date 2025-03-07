//
//  ExchangeRateViewModel.swift
//  CurrEx
//
//  Created for CurrEx on 05.03.2025.
//

import Foundation
import SwiftUI
import WidgetKit

// MARK: - Main Content View Model
final class ExchangeRateViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// Exchange rates data organized by currency
    @Published var ratesData: [CurrencyType: [BankRateViewModel]] = [:]
    
    /// Loading state indicator
    @Published var isLoading = true
    
    /// Error message to display if data loading fails
    @Published var errorMessage: String? = nil
    
    /// Timestamp when data was last updated in the app
    @Published var lastUpdated: String = ""
    
    /// Currently selected currency
    @Published var selectedCurrency: CurrencyType = .usd
    
    /// Timestamps from server for each currency, formatted for display
    @Published var lastUpdatedFromServer: [CurrencyType: String] = [:]

    // MARK: - Private Properties
    
    /// Service for fetching exchange rate data
    private let service: ExchangeRatesServiceProtocol
    
    /// Date formatter for consistent timestamp formatting
    private let dateFormatter: DateFormatter
    
    // MARK: - Initialization
    
    /// Initializes the view model with a service dependency
    /// - Parameter service: Service that provides exchange rate data
    init(service: ExchangeRatesServiceProtocol = ServiceContainer.shared.exchangeRatesService) {
        self.service = service
        
        // Initialize date formatter once for performance
        dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        dateFormatter.locale = Locale(identifier: "uk_UA")
        
        // Initialize the rates data dictionary with empty arrays
        for currency in CurrencyType.allCases {
            ratesData[currency] = []
        }
    }
    
    // MARK: - Data Loading Methods
    
    /// Loads exchange rate data for a specific currency
    /// - Parameter currency: Currency to load data for (defaults to selected currency)
    func loadData(for currency: CurrencyType? = nil) {
        let currencyToLoad = currency ?? selectedCurrency
        isLoading = true
        errorMessage = nil
        
        Task { @MainActor in
            do {
                let rates = try await service.fetchExchangeRates(for: currencyToLoad.rawValue)
                ratesData[currencyToLoad] = rates
                lastUpdated = formatCurrentTime()
                
                let isoFormatter = ISO8601DateFormatter()
                isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                
                if let rateData = rates.first, let date = isoFormatter.date(from: rateData.timestamp) {
                    lastUpdatedFromServer[currencyToLoad] = dateFormatter.string(from: date)
                }
                
                isLoading = false
            } catch {
                handleError(error)
            }
        }
    }
    
    /// Loads exchange rate data for all supported currencies and updates widget data
    func loadDataForAllCurrencies() {
        isLoading = true
        errorMessage = nil
        
        Task { @MainActor in
            do {
                var bestBuyRates: [String: WidgetExchangeRate] = [:]
                var bestSellRates: [String: WidgetExchangeRate] = [:]
                var allRates: [String: [WidgetExchangeRate]] = [:]
                
                for currency in CurrencyType.allCases {
                    let rates = try await service.fetchExchangeRates(for: currency.rawValue)
                    ratesData[currency] = rates
                    
                    // Find best rates using our view model logic
                    let bestRatesResult = findBestRates(for: currency)
                    
                    // Store all rates for the widget
                    var currencyRates: [WidgetExchangeRate] = []
                    for rate in rates {
                        currencyRates.append(WidgetExchangeRate(
                            currencyType: currency.rawValue,
                            buyRate: rate.buyRate,
                            sellRate: rate.sellRate,
                            bankName: rate.name,
                            timestamp: rate.timestamp
                        ))
                    }
                    allRates[currency.rawValue] = currencyRates
                    
                    // Save best rates for widgets
                    if let bestBuy = bestRatesResult.buy {
                        bestBuyRates[currency.rawValue] = WidgetExchangeRate(
                            currencyType: currency.rawValue,
                            buyRate: bestBuy.buyRate,
                            sellRate: bestBuy.sellRate,
                            bankName: bestBuy.name,
                            timestamp: bestBuy.timestamp
                        )
                    }
                    
                    if let bestSell = bestRatesResult.sell {
                        bestSellRates[currency.rawValue] = WidgetExchangeRate(
                            currencyType: currency.rawValue,
                            buyRate: bestSell.buyRate,
                            sellRate: bestSell.sellRate,
                            bankName: bestSell.name,
                            timestamp: bestSell.timestamp
                        )
                    }
                    
                    // Update timestamps
                    let isoFormatter = ISO8601DateFormatter()
                    isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    if let rateData = rates.first, let date = isoFormatter.date(from: rateData.timestamp) {
                        lastUpdatedFromServer[currency] = dateFormatter.string(from: date)
                    }
                }
                
                // Update widget data with all rates and best rates
                let widgetData = WidgetExchangeRateData(
                    bestBuyRates: bestBuyRates,
                    bestSellRates: bestSellRates,
                    allRates: allRates,
                    lastUpdated: Date()
                )
                WidgetDataManager.saveWidgetData(widgetData)
                
                // Notify widgets about updates
                WidgetCenter.shared.reloadAllTimelines()
                
                lastUpdated = formatCurrentTime()
                isLoading = false
            } catch {
                handleError(error)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Formats the current time using the configured date formatter
    /// - Returns: Formatted current time string
    private func formatCurrentTime() -> String {
        return dateFormatter.string(from: Date())
    }
    
    /// Handles errors from data loading
    /// - Parameter error: Error that occurred
    private func handleError(_ error: Error) {
        if let networkError = error as? NetworkError {
            errorMessage = NSLocalizedString("Data loading error: \(networkError.localizedDescription)", comment: "")
        } else {
            errorMessage = NSLocalizedString("Data loading error: \(error.localizedDescription)", comment: "")
        }
        isLoading = false
    }
    
    // MARK: - Data Access Methods
    
    /// Finds the best buy and sell rates for a given currency
    /// - Parameter currency: Currency to find rates for
    /// - Returns: Tuple containing best buy and sell rates
    func findBestRates(for currency: CurrencyType) -> (buy: BankRateViewModel?, sell: BankRateViewModel?) {
        guard let rates = ratesData[currency], !rates.isEmpty else { return (nil, nil) }
        
        var bestBuy = rates[0]
        var bestSell = rates[0]
        
        for rate in rates {
            // For buy rate, we want the highest value (best to sell at)
            if rate.buyRate > bestBuy.buyRate {
                bestBuy = rate
            }
            // For sell rate, we want the lowest value (best to buy at)
            if rate.sellRate < bestSell.sellRate {
                bestSell = rate
            }
        }
        
        return (bestBuy, bestSell)
    }
    
    /// Gets the y-axis domain range for charts
    /// - Parameter currency: Currency to get domain for
    /// - Returns: Closed range suitable for chart y-axis
    func getChartYDomain(for currency: CurrencyType) -> ClosedRange<Double> {
        guard let rates = ratesData[currency], !rates.isEmpty else { return 0...50 }
        
        let allRates = rates.flatMap { [$0.buyRate, $0.sellRate] }
        let minValue = (allRates.min() ?? 0) * 0.99
        let maxValue = (allRates.max() ?? 50) * 1.01
        
        return minValue...maxValue
    }
    
    /// Gets all available rates for a given currency
    /// - Parameter currency: Currency to get rates for
    /// - Returns: Array of bank rates
    func getRates(for currency: CurrencyType) -> [BankRateViewModel] {
        return ratesData[currency] ?? []
    }
    
    /// Gets the last update time from server for a given currency
    /// - Parameter currency: Currency to get update time for
    /// - Returns: Formatted update time string
    func getLastUpdatedFromServer(for currency: CurrencyType) -> String {
        return lastUpdatedFromServer[currency] ?? NSLocalizedString("Not updated", comment: "")
    }
}
