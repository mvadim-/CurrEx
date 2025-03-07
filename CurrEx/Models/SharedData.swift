//
//  SharedData.swift
//  CurrEx
//
//  Created for CurrEx on 05.03.2025.
//

import Foundation

/// Namespace for shared widget models
enum SharedWidgetModels {
    /// Exchange rate data for widget
    struct ExchangeRate: Identifiable, Codable {
        var id: String { bankName + currency }
        let currency: String
        let bankName: String
        let buyRate: Double
        let sellRate: Double
        let timestamp: String
        
        /// Sample exchange rate for preview
        static let example = ExchangeRate(
            currency: "USD",
            bankName: "PrivatBank",
            buyRate: 38.5,
            sellRate: 39.2,
            timestamp: "2025-03-05T12:00:00Z"
        )
    }
    
    /// Widget settings
    struct WidgetSettings: Codable {
        let selectedCurrency: String
        
        /// Default widget settings
        static let `default` = WidgetSettings(selectedCurrency: "USD")
    }
}

/// Shared service for widget data
enum SharedDataService {
    /// App group ID for shared data
    private static let appGroupID = "group.com.softjourn.CurrEx"
    
    /// Shared UserDefaults instance
    private static let sharedUserDefaults = UserDefaults(suiteName: appGroupID)
    
    /// Keys for UserDefaults
    private enum Keys {
        static let exchangeRatesData = "widgetExchangeRateData"
        static let widgetSettings = "widgetSettings"
        static let lastUpdateTime = "lastUpdateTime"
    }
    
    /// Get current widget settings
    /// - Returns: Widget settings
    static func getWidgetSettings() -> SharedWidgetModels.WidgetSettings {
        guard let sharedDefaults = sharedUserDefaults,
              let savedData = sharedDefaults.data(forKey: Keys.widgetSettings),
              let settings = try? JSONDecoder().decode(SharedWidgetModels.WidgetSettings.self, from: savedData) else {
            return .default
        }
        return settings
    }
    
    /// Save widget settings
    /// - Parameter settings: Widget settings to save
    static func saveWidgetSettings(_ settings: SharedWidgetModels.WidgetSettings) {
        guard let encoded = try? JSONEncoder().encode(settings),
              let sharedDefaults = sharedUserDefaults else {
            return
        }
        
        sharedDefaults.set(encoded, forKey: Keys.widgetSettings)
    }
    
    /// Get exchange rates for specific currency
    /// - Parameter currency: Currency code (e.g. "USD", "EUR")
    /// - Returns: Array of exchange rates
    static func getExchangeRates(for currency: String) -> [SharedWidgetModels.ExchangeRate] {
        guard let data = WidgetDataManager.loadWidgetData() else {
            return []
        }
        
        // Use all rates if available
        if let allRates = data.allRates[currency] {
            return allRates.map { rate in
                SharedWidgetModels.ExchangeRate(
                    currency: rate.currencyType,
                    bankName: rate.bankName,
                    buyRate: rate.buyRate,
                    sellRate: rate.sellRate,
                    timestamp: rate.timestamp
                )
            }
        }
        
        // Fallback to older approach if all rates aren't available
        var rates: [SharedWidgetModels.ExchangeRate] = []
        
        // Add best buy rate if available
        if let buyRate = data.bestBuyRates[currency] {
            rates.append(SharedWidgetModels.ExchangeRate(
                currency: buyRate.currencyType,
                bankName: buyRate.bankName,
                buyRate: buyRate.buyRate,
                sellRate: buyRate.sellRate,
                timestamp: buyRate.timestamp
            ))
        }
        
        // Add best sell rate if available and not already added
        if let sellRate = data.bestSellRates[currency],
           !rates.contains(where: { $0.bankName == sellRate.bankName }) {
            rates.append(SharedWidgetModels.ExchangeRate(
                currency: sellRate.currencyType,
                bankName: sellRate.bankName,
                buyRate: sellRate.buyRate,
                sellRate: sellRate.sellRate,
                timestamp: sellRate.timestamp
            ))
        }
        
        return rates
    }
    
    /// Get best buy rate for specific currency (directly from main app saved data)
    /// - Parameter currency: Currency code (e.g. "USD", "EUR")
    /// - Returns: Best exchange rate or nil if not available
    static func getBestBuyRate(for currency: String) -> SharedWidgetModels.ExchangeRate? {
        guard let data = WidgetDataManager.loadWidgetData(),
              let bestBuyRate = data.bestBuyRates[currency] else {
            return nil
        }
        
        return SharedWidgetModels.ExchangeRate(
            currency: bestBuyRate.currencyType,
            bankName: bestBuyRate.bankName,
            buyRate: bestBuyRate.buyRate,
            sellRate: bestBuyRate.sellRate,
            timestamp: bestBuyRate.timestamp
        )
    }
    
    /// Get best sell rate for specific currency (directly from main app saved data)
    /// - Parameter currency: Currency code (e.g. "USD", "EUR")
    /// - Returns: Best exchange rate or nil if not available
    static func getBestSellRate(for currency: String) -> SharedWidgetModels.ExchangeRate? {
        guard let data = WidgetDataManager.loadWidgetData(),
              let bestSellRate = data.bestSellRates[currency] else {
            return nil
        }
        
        return SharedWidgetModels.ExchangeRate(
            currency: bestSellRate.currencyType,
            bankName: bestSellRate.bankName,
            buyRate: bestSellRate.buyRate,
            sellRate: bestSellRate.sellRate,
            timestamp: bestSellRate.timestamp
        )
    }
    
    /// Get last time data was updated
    /// - Returns: Last update date or nil if not available
    static func getLastUpdateTime() -> Date? {
        guard let sharedDefaults = sharedUserDefaults else {
            return nil
        }
        return sharedDefaults.object(forKey: Keys.lastUpdateTime) as? Date
    }
}

/// Widget data manager for exchange rate data
enum WidgetDataManager {
    /// App group ID for shared data
    static let appGroupID = "group.com.softjourn.CurrEx"
    
    /// Shared UserDefaults instance
    static let sharedUserDefaults = UserDefaults(suiteName: appGroupID)
    
    /// Key for exchange rate data
    static let widgetDataKey = "widgetExchangeRateData"
    
    /// Save widget data to shared UserDefaults
    /// - Parameter data: Exchange rate data to save
    static func saveWidgetData(_ data: WidgetExchangeRateData) {
        guard let encoded = try? JSONEncoder().encode(data) else {
            print("Failed to encode widget data")
            return
        }
        sharedUserDefaults?.set(encoded, forKey: widgetDataKey)
        sharedUserDefaults?.set(Date(), forKey: "lastUpdateTime")
    }
    
    /// Load widget data from shared UserDefaults
    /// - Returns: Exchange rate data or nil if not available
    static func loadWidgetData() -> WidgetExchangeRateData? {
        guard let sharedDefaults = sharedUserDefaults,
              let savedData = sharedDefaults.data(forKey: widgetDataKey) else {
            return nil
        }
        
        return try? JSONDecoder().decode(WidgetExchangeRateData.self, from: savedData)
    }
}

/// Data structure for exchange rate data shared with widget
struct WidgetExchangeRateData: Codable {
    let bestBuyRates: [String: WidgetExchangeRate]
    let bestSellRates: [String: WidgetExchangeRate]
    let allRates: [String: [WidgetExchangeRate]]
    let lastUpdated: Date
    
    /// Empty data structure
    static var empty: WidgetExchangeRateData {
        return WidgetExchangeRateData(
            bestBuyRates: [:],
            bestSellRates: [:],
            allRates: [:],
            lastUpdated: Date()
        )
    }
}

/// Individual exchange rate for widget
struct WidgetExchangeRate: Codable {
    let currencyType: String
    let buyRate: Double
    let sellRate: Double
    let bankName: String
    let timestamp: String
    
    /// Sample exchange rate for preview
    static let example = WidgetExchangeRate(
        currencyType: "USD",
        buyRate: 38.5,
        sellRate: 39.2,
        bankName: "PrivatBank",
        timestamp: "2025-03-05T12:00:00Z"
    )
}
