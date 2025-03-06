// SharedData.swift
import Foundation

struct WidgetExchangeRate: Codable {
    let currencyType: String
    let buyRate: Double
    let sellRate: Double
    let bankName: String
    let timestamp: String
    
    static let example = WidgetExchangeRate(
        currencyType: "USD",
        buyRate: 38.5,
        sellRate: 39.2,
        bankName: "PrivatBank",
        timestamp: "2025-03-05T12:00:00Z"
    )
}

struct WidgetExchangeRateData: Codable {
    let bestBuyRates: [String: WidgetExchangeRate]
    let bestSellRates: [String: WidgetExchangeRate]
    let lastUpdated: Date
    
    static var empty: WidgetExchangeRateData {
        return WidgetExchangeRateData(
            bestBuyRates: [:],
            bestSellRates: [:],
            lastUpdated: Date()
        )
    }
}

enum WidgetDataManager {
    static let appGroupID = "group.com.softjourn.CurrEx" // Змініть на ваш ID групи
    static let sharedUserDefaults = UserDefaults(suiteName: appGroupID)
    static let widgetDataKey = "widgetExchangeRateData"
    
    static func saveWidgetData(_ data: WidgetExchangeRateData) {
        guard let encoded = try? JSONEncoder().encode(data) else {
            print("Failed to encode widget data")
            return
        }
        sharedUserDefaults?.set(encoded, forKey: widgetDataKey)
    }
    
    static func loadWidgetData() -> WidgetExchangeRateData {
        guard let sharedDefaults = sharedUserDefaults,
              let savedData = sharedDefaults.data(forKey: widgetDataKey),
              let decodedData = try? JSONDecoder().decode(WidgetExchangeRateData.self, from: savedData) else {
            return .empty
        }
        return decodedData
    }
}
