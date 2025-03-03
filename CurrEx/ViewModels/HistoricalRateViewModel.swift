//
//  HistoricalRatesViewModel.swift
//  CurrEx
//

import Foundation
import SwiftUI

// MARK: - Historical Data View Model
class HistoricalRatesViewModel: ObservableObject {
    @Published var historicalData: [HistoricalRateDataPoint] = []
    @Published var isLoading = true
    @Published var errorMessage: String? = nil
    @Published var selectedPeriod: PeriodType = .day1
    @Published var selectedCurrency: CurrencyType = .usd
    @Published var visibleBanks: Set<String> = ["Bestobmin", "PrivatBank", "Raiffeisen"]
    @Published var lastUpdated: String = ""
    
    private let service = HistoricalExchangeRatesService()
    private let dateFormatter: DateFormatter
    
    init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        dateFormatter.locale = Locale(identifier: "uk_UA")
    }
    
    func loadData() {
        isLoading = true
        errorMessage = nil
        
        Task { @MainActor in
            do {
                historicalData = try await service.fetchHistoricalRates(
                    for: selectedCurrency.rawValue,
                    period: selectedPeriod.rawValue
                )
                lastUpdated = formatCurrentTime()
                
                // Ensure we have valid banks to display
                updateVisibleBanks()
                
                isLoading = false
            } catch {
                errorMessage = "Помилка завантаження історичних даних: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    private func formatCurrentTime() -> String {
        return dateFormatter.string(from: Date())
    }
    
    func toggleBank(_ bank: String) {
        if visibleBanks.contains(bank) {
            visibleBanks.remove(bank)
        } else {
            visibleBanks.insert(bank)
        }
    }
    
    func isBankVisible(_ bank: String) -> Bool {
        return visibleBanks.contains(bank)
    }
    
    // Update visible banks based on available data
    private func updateVisibleBanks() {
        if historicalData.isEmpty {
            return
        }
        
        // Get a list of banks that actually have data
        var availableBanks: Set<String> = []
        
        for dataPoint in historicalData {
            for (bank, _) in dataPoint.bankRates {
                availableBanks.insert(bank)
            }
        }
        
        // Only show banks that have data
        visibleBanks = visibleBanks.intersection(availableBanks)
        
        // If all were filtered out, show all available banks
        if visibleBanks.isEmpty {
            visibleBanks = availableBanks
        }
    }
    
    func getDateRange() -> String {
        guard let firstDate = historicalData.first?.date, let lastDate = historicalData.last?.date else {
            return "Немає даних"
        }
        
        let startDateString = dateFormatter.string(from: firstDate)
        let endDateString = dateFormatter.string(from: lastDate)
        
        return "\(startDateString) - \(endDateString)"
    }
    
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
}
