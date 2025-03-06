//
//  SmallWidgetView.swift
//  CurrExWidget
//
//  Created for CurrEx on 05.03.2025.
//

import SwiftUI
import WidgetKit

/// Представлення для малого віджета
struct SmallWidgetView: View {
    /// Дані для відображення у віджеті
    let entry: ExchangeRateEntry
    
    /// Колір для курсу продажу
    private let buyColor = Color("BuyColor")
    
    /// Колір для курсу купівлі
    private let sellColor = Color("SellColor")
    
    var body: some View {
        VStack(spacing: 8) {
            // Заголовок з валютою
            HStack {
                Text(entry.currency)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                // Відображаємо час останнього оновлення
                Text("оновлено \(entry.formattedUpdateTime)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if entry.hasData {
                // Найкращий курс для продажу валюти
                if let bestBuy = entry.bestBuyRate {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Продати:")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text(bestBuy.bankName)
                                .font(.caption)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Text(String(format: "%.2f", bestBuy.buyRate))
                                .font(.body)
                                .fontWeight(.bold)
                                .foregroundColor(buyColor)
                        }
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(buyColor.opacity(0.1))
                    .cornerRadius(6)
                }
                
                // Найкращий курс для купівлі валюти
                if let bestSell = entry.bestSellRate {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Купити:")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text(bestSell.bankName)
                                .font(.caption)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Text(String(format: "%.2f", bestSell.sellRate))
                                .font(.body)
                                .fontWeight(.bold)
                                .foregroundColor(sellColor)
                        }
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(sellColor.opacity(0.1))
                    .cornerRadius(6)
                }
            } else {
                // Відображаємо повідомлення про відсутність даних
                Text("Немає даних")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
    }
}

struct SmallWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        SmallWidgetView(entry: ExchangeRateEntry(
            date: Date(),
            currency: "USD",
            rates: [
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
                )
            ]
        ))
        .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
