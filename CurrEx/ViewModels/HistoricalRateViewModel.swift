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
    
    func getDateRange() -> String {
        guard let firstDate = historicalData.first?.date, let lastDate = historicalData.last?.date else {
            return "Немає даних"
        }
        
        let startDateString = dateFormatter.string(from: firstDate)
        let endDateString = dateFormatter.string(from: lastDate)
        
        return "\(startDateString) - \(endDateString)"
    }
    
    func getYDomain() -> ClosedRange<Double> {
        var minValue: Double = Double.greatestFiniteMagnitude
        var maxValue: Double = 0
        
        for dataPoint in historicalData {
            for bank in visibleBanks {
                let buyRate = dataPoint.getBuyRate(for: bank)
                let sellRate = dataPoint.getSellRate(for: bank)
                
                if buyRate > 0 && buyRate < minValue {
                    minValue = buyRate
                }
                
                if sellRate > maxValue {
                    maxValue = sellRate
                }
            }
        }
        
        // Add some padding for better visualization
        minValue = max(0, minValue * 0.99)
        maxValue = maxValue * 1.01
        
        return minValue == Double.greatestFiniteMagnitude ? 0...50 : minValue...maxValue
    }
}
