//
//  ExchangeRateProvider.swift
//  CurrExWidget
//
//  Created for CurrEx on 05.03.2025.
//

import WidgetKit
import SwiftUI

/// Постачальник даних для віджета
struct ExchangeRateProvider: TimelineProvider {
    typealias Entry = ExchangeRateEntry
    
    /// Налаштування віджета
    let settings = SharedDataService.getWidgetSettings()
    
    /// Надає заглушку для попереднього перегляду віджета
    /// - Parameter context: Контекст віджета
    /// - Returns: Заглушка для відображення у віджеті
    func placeholder(in context: Context) -> Entry {
        // Створюємо заглушку з фіктивними даними
        let placeholder = [
            SharedWidgetModels.ExchangeRate(
                currency: "USD",
                bankName: "PrivatBank",
                buyRate: 38.5,
                sellRate: 39.2,
                timestamp: ""
            ),
            SharedWidgetModels.ExchangeRate(
                currency: "USD",
                bankName: "Bestobmin",
                buyRate: 38.7,
                sellRate: 39.1,
                timestamp: ""
            ),
            SharedWidgetModels.ExchangeRate(
                currency: "USD",
                bankName: "Raiffeisen",
                buyRate: 38.3,
                sellRate: 38.9,
                timestamp: ""
            )
        ]
        
        return Entry(
            date: Date(),
            currency: settings.selectedCurrency,
            rates: placeholder
        )
    }
    
    /// Надає знімок даних для відображення у віджеті
    /// - Parameters:
    ///   - context: Контекст віджета
    ///   - completion: Замикання для отримання знімка
    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        // У режимі пібліду використовуємо заглушку
        if context.isPreview {
            completion(placeholder(in: context))
            return
        }
        
        // В іншому випадку беремо реальні дані
        let currency = settings.selectedCurrency
        let rates = SharedDataService.getExchangeRates(for: currency)
        let date = SharedDataService.getLastUpdateTime() ?? Date()
        
        let entry = Entry(
            date: date,
            currency: currency,
            rates: rates
        )
        
        completion(entry)
    }
    
    /// Надає часовий графік оновлень для віджета
    /// - Parameters:
    ///   - context: Контекст віджета
    ///   - completion: Замикання для отримання часового графіка
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        // Отримуємо реальні дані
        let currency = settings.selectedCurrency
        let rates = SharedDataService.getExchangeRates(for: currency)
        let date = SharedDataService.getLastUpdateTime() ?? Date()
        
        let entry = Entry(
            date: date,
            currency: currency,
            rates: rates
        )
        
        // Оновлюємо віджет кожні 30 хвилин
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        
        // Створюємо часову лінію з одним елементом
        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        
        completion(timeline)
    }
}
