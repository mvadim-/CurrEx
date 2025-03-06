//
//  LargeWidgetView.swift
//  CurrExWidget
//
//  Created for CurrEx on 05.03.2025.
//

import SwiftUI
import WidgetKit

/// Представлення для великого віджета
struct LargeWidgetView: View {
    /// Дані для відображення у віджеті
    let entry: ExchangeRateEntry
    
    /// Колір для курсу продажу
    private let buyColor = Color("BuyColor")
    
    /// Колір для курсу купівлі
    private let sellColor = Color("SellColor")
    
    var body: some View {
        VStack(spacing: 12) {
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
                // Найкращі курси
                HStack(spacing: 12) {
                    // Найкращий курс для продажу валюти
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Найкраще продати")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        if let bestBuy = entry.bestBuyRate {
                            Text(bestBuy.bankName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text(String(format: "%.2f", bestBuy.buyRate))
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(buyColor)
                        } else {
                            Text("Немає даних")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(buyColor.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Найкращий курс для купівлі валюти
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Найкраще купити")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        if let bestSell = entry.bestSellRate {
                            Text(bestSell.bankName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text(String(format: "%.2f", bestSell.sellRate))
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(sellColor)
                        } else {
                            Text("Немає даних")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(sellColor.opacity(0.1))
                    .cornerRadius(12)
                }
                .frame(height: 120)
                
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
                        
                        Text("Спред")
                            .font(.caption)
                            .fontWeight(.medium)
                            .frame(width: 70, alignment: .trailing)
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.secondary.opacity(0.1))
                    
                    // Дані про курси валют
                    ForEach(entry.rates) { rate in
                        HStack {
                            Text(rate.bankName)
                                .font(.subheadline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Text(String(format: "%.2f", rate.sellRate))
                                .font(.subheadline)
                                .foregroundColor(sellColor)
                                .frame(width: 70, alignment: .trailing)
                            
                            Text(String(format: "%.2f", rate.buyRate))
                                .font(.subheadline)
                                .foregroundColor(buyColor)
                                .frame(width: 70, alignment: .trailing)
                            
                            let spread = rate.sellRate - rate.buyRate
                            Text(String(format: "%.2f", spread))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(width: 70, alignment: .trailing)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        
                        // Додаємо роздільник для всіх рядків, окрім останнього
                        if rate.id != entry.rates.last?.id {
                            Divider()
                                .padding(.horizontal, 12)
                        }
                    }
                }
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(12)
                
                // Примітка
                HStack {
                    Text("Для конвертації та детальної інформації натисніть на віджет")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 8)
            } else {
                // Відображаємо повідомлення про відсутність даних
                Spacer()
                
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    
                    Text("Немає даних про курси валют")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                    
                    Text("Відкрийте додаток для оновлення даних")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                
                Spacer()
            }
        }
        .padding()
    }
}

// Превью для великого віджета
struct LargeWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        LargeWidgetView(entry: ExchangeRateEntry(
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
        .previewContext(WidgetPreviewContext(family: .systemLarge))
    }
}
