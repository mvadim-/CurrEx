//
//  MediumWidgetView.swift
//  CurrExWidget
//
//  Created for CurrEx on 05.03.2025.
//

import SwiftUI
import WidgetKit

/// Представлення для середнього віджета
struct MediumWidgetView: View {
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
                Text("Курс \(entry.currency)")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                // Відображаємо час останнього оновлення
                Text("оновлено \(entry.formattedUpdateTime)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if entry.hasData {
                // Таблиця з курсами валют
                VStack(spacing: 0) {
                    // Заголовок таблиці
                    HStack {
                        Text("Банк")
                            .font(.caption)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("Купити")
                            .font(.caption)
                            .fontWeight(.medium)
                            .frame(width: 70, alignment: .trailing)
                        
                        Text("Продати")
                            .font(.caption)
                            .fontWeight(.medium)
                            .frame(width: 70, alignment: .trailing)
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.1))
                    
                    // Дані про курси валют
                    ForEach(entry.rates) { rate in
                        HStack {
                            Text(rate.bankName)
                                .font(.caption)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Text(String(format: "%.2f", rate.sellRate))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(sellColor)
                                .frame(width: 70, alignment: .trailing)
                            
                            Text(String(format: "%.2f", rate.buyRate))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(buyColor)
                                .frame(width: 70, alignment: .trailing)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        
                        // Додаємо роздільник для всіх рядків, окрім останнього
                        if rate.id != entry.rates.last?.id {
                            Divider()
                                .padding(.horizontal, 12)
                        }
                    }
                }
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(8)
                
                // Найкращі курси
                HStack(spacing: 8) {
                    // Найкращий курс для продажу валюти
                    if let bestBuy = entry.bestBuyRate {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Найкраще продати")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Text(bestBuy.bankName)
                                    .font(.caption)
                                
                                Spacer()
                                
                                Text(String(format: "%.2f", bestBuy.buyRate))
                                    .font(.callout)
                                    .fontWeight(.bold)
                                    .foregroundColor(buyColor)
                            }
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(buyColor.opacity(0.1))
                        .cornerRadius(6)
                        .frame(maxWidth: .infinity)
                    }
                    
                    // Найкращий курс для купівлі валюти
                    if let bestSell = entry.bestSellRate {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Найкраще купити")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Text(bestSell.bankName)
                                    .font(.caption)
                                
                                Spacer()
                                
                                Text(String(format: "%.2f", bestSell.sellRate))
                                    .font(.callout)
                                    .fontWeight(.bold)
                                    .foregroundColor(sellColor)
                            }
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(sellColor.opacity(0.1))
                        .cornerRadius(6)
                        .frame(maxWidth: .infinity)
                    }
                }
            } else {
                // Відображаємо повідомлення про відсутність даних
                Spacer()
                
                Text("Немає даних про курси валют")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        }
        .padding()
    }
}

struct MediumWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        MediumWidgetView(entry: ExchangeRateEntry(
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
                ),
                SharedWidgetModels.ExchangeRate(
                    currency: "USD",
                    bankName: "Bestobmin",
                    buyRate: 38.7,
                    sellRate: 39.1,
                    timestamp: ""
                )
            ]
        ))
        .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
