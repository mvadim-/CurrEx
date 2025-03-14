//
//  HistoricalRatesViewModel.swift
//  CurrEx
//
//  Created for CurrEx on 05.03.2025.
//

import Foundation
import SwiftUI

// MARK: - Historical Data View Model
final class HistoricalRatesViewModel: ObservableObject {
    // Published properties for UI updates
    @Published var historicalData: [HistoricalRateDataPoint] = []
    @Published var isLoading = true
    @Published var errorMessage: String? = nil
    @Published var selectedPeriod: PeriodType = .day1 // Changed default to 1 day
    @Published var selectedCurrency: CurrencyType = .usd
    @Published var visibleBanks: Set<String> = []
    @Published var lastUpdated: String = ""
    
    // Dependencies
    private let service: HistoricalExchangeRatesServiceProtocol
    private let dateFormatter: DateFormatter
    private let settingsManager = SettingsManager.shared
    
    // Observer for bank visibility changes
    private var bankVisibilityObserver: NSObjectProtocol?
    
    // MARK: - Initialization
    
    /// Initializes the view model with a service dependency
    /// - Parameter service: Service that provides historical exchange rate data
    init(service: HistoricalExchangeRatesServiceProtocol = ServiceContainer.shared.historicalExchangeRatesService) {
        self.service = service
        
        dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        dateFormatter.locale = Locale(identifier: "uk_UA")
        
        // Load visible banks from settings
        visibleBanks = settingsManager.visibleBanks
        
        // Observe bank visibility changes
        bankVisibilityObserver = NotificationCenter.default.addObserver(
            forName: Notification.Name("BankVisibilityChanged"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            // Update visible banks when settings change
            self.visibleBanks = self.settingsManager.visibleBanks
            // Trigger UI update
            self.objectWillChange.send()
        }
    }
    
    deinit {
        // Remove observer when view model is deallocated
        if let observer = bankVisibilityObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - Data Loading
    
    /// Loads historical exchange rate data
    func loadData() {
        isLoading = true
        errorMessage = nil
        
        Task { @MainActor in
            do {
                historicalData = try await service.fetchHistoricalRates(
                    for: selectedCurrency.rawValue,
                    period: selectedPeriod.rawValue
                )
                lastUpdated = Formatters.formatCurrentDateTime()
                
                // Get all available banks from data
                updateAvailableBanks()
                
                // Get visible banks from settings
                visibleBanks = settingsManager.visibleBanks
                
                isLoading = false
            } catch {
                handleError(error)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Handles errors from data loading
    /// - Parameter error: Error that occurred
    private func handleError(_ error: Error) {
        if let networkError = error as? NetworkError {
            errorMessage = NSLocalizedString("Historical data loading error: \(networkError.localizedDescription)", comment: "")
        } else {
            errorMessage = NSLocalizedString("Historical data loading error: \(error.localizedDescription)", comment: "")
        }
        isLoading = false
    }
    
    /// Updates the available banks in settings based on fetched data
    private func updateAvailableBanks() {
        if historicalData.isEmpty {
            return
        }
        
        // Get a list of banks that actually have data
        var availableBanks = Set<String>()
        
        for dataPoint in historicalData {
            for (bank, _) in dataPoint.bankRates {
                availableBanks.insert(bank)
            }
        }
        
        // Update available banks in settings manager
        settingsManager.updateAvailableBanks(Array(availableBanks))
    }
    
    /// Gets the date range covered by historical data
    /// - Returns: Formatted date range string
    func getDateRange() -> String {
        guard let firstDate = historicalData.first?.date, let lastDate = historicalData.last?.date else {
            return NSLocalizedString("No data", comment: "")
        }
        
        let startDateString = dateFormatter.string(from: firstDate)
        let endDateString = dateFormatter.string(from: lastDate)
        
        return "\(startDateString) - \(endDateString)"
    }
    
    /// Gets the y-axis domain range for charts
    /// - Returns: Closed range suitable for chart y-axis
    func getYDomain() -> ClosedRange<Double> {
        // Default domain in case of errors
        let defaultDomain: ClosedRange<Double> = 0...50
        
        // Exit early if there's no data
        if historicalData.isEmpty || visibleBanks.isEmpty {
            return defaultDomain
        }
        
        var allValues: [Double] = []
        
        // Collect all valid rate values
        for dataPoint in historicalData {
            for bank in visibleBanks {
                if let bankRate = dataPoint.bankRates[bank] {
                    if bankRate.buy > 0 {
                        allValues.append(bankRate.buy)
                    }
                    if bankRate.sell > 0 {
                        allValues.append(bankRate.sell)
                    }
                }
            }
        }
        
        // If we don't have any values, return default domain
        if allValues.isEmpty {
            return defaultDomain
        }
        
        // Calculate min and max with padding
        let minValue = (allValues.min() ?? 0) * 0.99
        let maxValue = (allValues.max() ?? 50) * 1.01
        
        return minValue...maxValue
    }
    
    /// Gets filtered historical data based on visible banks
    func getFilteredData() -> [HistoricalRateDataPoint] {
        return historicalData
    }
    
    /// Checks if a bank is available in the current data
    /// - Parameter bank: Bank name to check
    /// - Returns: True if bank has data available
    func isBankAvailable(_ bank: String) -> Bool {
        if historicalData.isEmpty {
            return false
        }
        
        return historicalData.contains { dataPoint in
            dataPoint.bankRates.keys.contains(bank)
        }
    }
    
    /// Checks if a bank is currently visible
    /// - Parameter bank: Bank name to check
    /// - Returns: True if bank is visible
    func isBankVisible(_ bank: String) -> Bool {
        return visibleBanks.contains(bank)
    }
    
    /// Toggles visibility of a bank in the chart
    /// - Parameter bank: Bank name to toggle
    func toggleBank(_ bank: String) {
        if isBankVisible(bank) {
            // Don't allow hiding the last visible bank
            if visibleBanks.count > 1 {
                visibleBanks.remove(bank)
            }
        } else {
            visibleBanks.insert(bank)
        }
    }
}
