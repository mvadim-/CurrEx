//
//  ExchangeRateEntry.swift
//  CurrExWidget
//
//  Created for CurrEx on 05.03.2025.
//

import WidgetKit

/// Модель даних для віджета
struct ExchangeRateEntry: TimelineEntry {
    /// Дата оновлення даних
    let date: Date
    
    /// Валюта (USD, EUR тощо)
    let currency: String
    
    /// Курси валют для відображення у віджеті
    let rates: [SharedWidgetModels.ExchangeRate]
    
    /// Форматований час останнього оновлення
    var formattedUpdateTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "uk_UA")
        return formatter.string(from: date)
    }
    
    /// Отримує найкращий курс для продажу валюти
    var bestBuyRate: SharedWidgetModels.ExchangeRate? {
        rates.max(by: { $0.buyRate < $1.buyRate })
    }
    
    /// Отримує найкращий курс для купівлі валюти
    var bestSellRate: SharedWidgetModels.ExchangeRate? {
        rates.min(by: { $0.sellRate > $1.sellRate })
    }
    
    /// Перевіряє, чи є дані про курси валют
    var hasData: Bool {
        !rates.isEmpty
    }
}
