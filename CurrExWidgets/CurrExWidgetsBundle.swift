//
//  CurrExWidgetsBundle.swift
//  CurrExWidgets
//
//  Created by Vadym Maslov on 06.03.2025.
//
//
//import WidgetKit
//import SwiftUI
//
//@main
//struct CurrExWidgetsBundle: WidgetBundle {
//    var body: some Widget {
//        CurrExWidgets()
//
//    }
//}
//// А ваш CurrExWidget має виглядати приблизно так:
//struct CurrExWidget: Widget {
//    let kind: String = "CurrExWidget"
//
//    var body: some WidgetConfiguration {
//        StaticConfiguration(kind: kind, provider: Provider()) { entry in
//            CurrExWidgetEntryView(entry: entry)
//        }
//        .configurationDisplayName("Курси валют")
//        .description("Відображає поточні курси валют")
//        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
//    }
//}
