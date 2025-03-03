//
//  ExchangeRateViewModel.swift
//  CurrEx
//

import Foundation
import SwiftUI

// MARK: - Main Content View Model
class ExchangeRateViewModel: ObservableObject {
    @Published var ratesData: [CurrencyType: [BankRateViewModel]] = [:]
    @Published var isLoading = true
    @Published var errorMessage: String? = nil
    @Published var lastUpdated: String = ""
    @Published var selectedCurrency: CurrencyType = .usd
    @Published var lastUpdatedFromServer: [CurrencyType: String] = [:]

    private let service = ExchangeRatesService()
    private let dateFormatter: DateFormatter
    
    init() {
        // Initialize date formatter once
        dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        dateFormatter.locale = Locale(identifier: "uk_UA")
        
        // Initialize the rates data dictionary
        for currency in CurrencyType.allCases {
            ratesData[currency] = []
        }
    }
    
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
                errorMessage = "Помилка завантаження даних: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    func loadDataForAllCurrencies() {
        isLoading = true
        errorMessage = nil
        
        Task { @MainActor in
            do {
                for currency in CurrencyType.allCases {
                    let rates = try await service.fetchExchangeRates(for: currency.rawValue)
                    ratesData[currency] = rates
                    
                    let isoFormatter = ISO8601DateFormatter()
                    isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    
                    if let rateData = rates.first, let date = isoFormatter.date(from: rateData.timestamp) {
                        lastUpdatedFromServer[currency] = dateFormatter.string(from: date)
                    }
                }
                
                lastUpdated = formatCurrentTime()
                isLoading = false
            } catch {
                errorMessage = "Помилка завантаження даних: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    private func formatCurrentTime() -> String {
        return dateFormatter.string(from: Date())
    }
    
    func findBestRates(for currency: CurrencyType) -> (buy: BankRateViewModel?, sell: BankRateViewModel?) {
        guard let rates = ratesData[currency], !rates.isEmpty else { return (nil, nil) }
        
        var bestBuy = rates[0]
        var bestSell = rates[0]
        
        for rate in rates {
            if rate.buyRate > bestBuy.buyRate {
                bestBuy = rate
            }
            if rate.sellRate < bestSell.sellRate {
                bestSell = rate
            }
        }
        
        return (bestBuy, bestSell)
    }
    
    func getChartYDomain(for currency: CurrencyType) -> ClosedRange<Double> {
        guard let rates = ratesData[currency], !rates.isEmpty else { return 0...50 }
        
        let minValue = (rates.map { $0.buyRate }.min() ?? 0) * 0.99
        let maxValue = (rates.map { $0.sellRate }.max() ?? 50) * 1.01
        
        return minValue...maxValue
    }
    
    func getRates(for currency: CurrencyType) -> [BankRateViewModel] {
        return ratesData[currency] ?? []
    }
    
    func getLastUpdatedFromServer(for currency: CurrencyType) -> String {
        return lastUpdatedFromServer[currency] ?? "Не оновлено"
    }
}
