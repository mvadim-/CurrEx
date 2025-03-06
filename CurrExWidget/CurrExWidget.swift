//
//  CurrExWidget.swift
//  CurrExWidget
//
//  Created for CurrEx on 05.03.2025.
//

import WidgetKit
import SwiftUI

/// Головний віджет, який відображає курси валют
@main
struct CurrExWidget: Widget {
    /// Ідентифікатор типу віджета
    private let kind = "CurrExWidget"
    
    /// Конфігурація віджета
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ExchangeRateProvider()) { entry in
            ExchangeRateWidgetView(entry: entry)
        }
        .configurationDisplayName("Курси валют")
        .description("Відображає поточні курси валют від різних банків.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
