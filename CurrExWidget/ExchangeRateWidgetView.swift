//
//  ExchangeRateWidgetView.swift
//  CurrExWidget
//
//  Created for CurrEx on 05.03.2025.
//

import WidgetKit
import SwiftUI

/// Головне представлення для віджета
struct ExchangeRateWidgetView: View {
    /// Розмір віджета
    @Environment(\.widgetFamily) var family
    
    /// Дані для відображення у віджеті
    var entry: ExchangeRateProvider.Entry
    
    var body: some View {
        ZStack {
            // Фоновий колір
            Color(UIColor.systemBackground)
                .edgesIgnoringSafeArea(.all)
            
            // Вибираємо макет в залежності від розміру віджета
            switch family {
            case .systemSmall:
                SmallWidgetView(entry: entry)
            case .systemMedium:
                MediumWidgetView(entry: entry)
            case .systemLarge:
                LargeWidgetView(entry: entry)
            default:
                MediumWidgetView(entry: entry)
            }
        }
        .widgetURL(URL(string: "currex://widget?currency=\(entry.currency)"))
    }
}

struct ExchangeRateWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleEntry = ExchangeRateEntry(
            date: Date(),
            currency: "USD",
            rates:  [
                SharedWidgetModels.ExchangeRate(
                    currency: "USD",
                    bankName: "PrivatBank",
                    buyRate: 38.5,
                    sellRate: 39.2,
                    timestamp: ""
                ),
                SharedWidgetModels.ExchangeRate(
                    currency: "USD",
                    bankName: "Raiffeisen",
                    buyRate: 38.3,
                    sellRate: 38.9,
                    timestamp: ""
                ),
                SharedWidgetModels.ExchangeRate(
                    currency: "USD",
                    bankName: "Bestobmin",
                    buyRate: 38.7,
                    sellRate: 39.1,
                    timestamp: ""
                )
            ]
        )
        
        Group {
            ExchangeRateWidgetView(entry: sampleEntry)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
            
            ExchangeRateWidgetView(entry: sampleEntry)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
            
            ExchangeRateWidgetView(entry: sampleEntry)
                .previewContext(WidgetPreviewContext(family: .systemLarge))
        }
    }
}
