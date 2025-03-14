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
    
    /// Settings manager for bank visibility
    private let settingsManager = SettingsManager.shared
    
    /// Cancellable for notification observations
    private var bankVisibilityObserver: NSObjectProtocol?
    
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
        
        // Observe bank visibility changes
        bankVisibilityObserver = NotificationCenter.default.addObserver(
            forName: Notification.Name("BankVisibilityChanged"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // Refresh UI when bank visibility changes
            self?.objectWillChange.send()
        }
    }
    
    deinit {
        // Remove observer when view model is deallocated
        if let observer = bankVisibilityObserver {
            NotificationCenter.default.removeObserver(observer)
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
                
                // Update available banks in settings manager
                let bankNames = rates.map { $0.name }
                settingsManager.updateAvailableBanks(bankNames)
                
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
                var allBankNames = Set<String>()
                
                for currency in CurrencyType.allCases {
                    let rates = try await service.fetchExchangeRates(for: currency.rawValue)
                    ratesData[currency] = rates
                    
                    // Collect all bank names for settings
                    rates.forEach { allBankNames.insert($0.name) }
                    
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
                
                // Update available banks in settings manager
                settingsManager.updateAvailableBanks(Array(allBankNames))
                
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
        let visibleRates = getFilteredRates(for: currency)
        guard !visibleRates.isEmpty else { return (nil, nil) }
        
        var bestBuy = visibleRates[0]
        var bestSell = visibleRates[0]
        
        for rate in visibleRates {
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
        let visibleRates = getFilteredRates(for: currency)
        guard !visibleRates.isEmpty else { return 0...50 }
        
        let allRates = visibleRates.flatMap { [$0.buyRate, $0.sellRate] }
        let minValue = (allRates.min() ?? 0) * 0.99
        let maxValue = (allRates.max() ?? 50) * 1.01
        
        return minValue...maxValue
    }
    
    /// Gets visible rates for a given currency based on user preferences
    /// - Parameter currency: Currency to get rates for
    /// - Returns: Array of bank rates filtered by visibility settings
    func getRates(for currency: CurrencyType) -> [BankRateViewModel] {
        return getFilteredRates(for: currency)
    }
    
    /// Gets the last update time from server for a given currency
    /// - Parameter currency: Currency to get update time for
    /// - Returns: Formatted update time string
    func getLastUpdatedFromServer(for currency: CurrencyType) -> String {
        return lastUpdatedFromServer[currency] ?? NSLocalizedString("Not updated", comment: "")
    }
    
    // MARK: - Private Helper Methods
    
    /// Filters rates based on user visibility preferences
    /// - Parameter currency: Currency to filter rates for
    /// - Returns: Filtered array of bank rates
    private func getFilteredRates(for currency: CurrencyType) -> [BankRateViewModel] {
        let allRates = ratesData[currency] ?? []
        // Only return rates for banks that are visible in settings
        return allRates.filter { settingsManager.isBankVisible($0.name) }
    }
}
