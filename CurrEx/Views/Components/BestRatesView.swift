//
//  BestRatesView.swift
//  CurrEx
//
//  Created for CurrEx on 05.03.2025.
//

import SwiftUI

/// View showing the best buy and sell rates
struct BestRatesView: View {
    let bestBuy: BankRateViewModel?
    let bestSell: BankRateViewModel?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("Best Rates", comment: "Best rates section title"))
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.text)
            
            HStack(spacing: 12) {
                // Best buy rates
                VStack(alignment: .leading, spacing: 6) {
                    Text(NSLocalizedString("Best to sell at", comment: "Best to sell at label"))
                        .font(.caption)
                        .foregroundColor(AppColors.secondaryText)
                    
                    if let bestBuy = bestBuy {
                        Text("\(bestBuy.name): \(String(format: "%.2f", bestBuy.buyRate)) ₴")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.buyColor)
                    } else {
                        Text(NSLocalizedString("No data", comment: "No data placeholder"))
                            .font(.title3)
                            .foregroundColor(AppColors.tertiaryText)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.buyColor.opacity(0.1))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(AppColors.buyColor.opacity(0.3), lineWidth: 1)
                )
                
                // Best sell rates
                VStack(alignment: .leading, spacing: 6) {
                    Text(NSLocalizedString("Best to buy at", comment: "Best to buy at label"))
                        .font(.caption)
                        .foregroundColor(AppColors.secondaryText)
                    
                    if let bestSell = bestSell {
                        Text("\(bestSell.name): \(String(format: "%.2f", bestSell.sellRate)) ₴")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.sellColor)
                    } else {
                        Text(NSLocalizedString("No data", comment: "No data placeholder"))
                            .font(.title3)
                            .foregroundColor(AppColors.tertiaryText)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.sellColor.opacity(0.1))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(AppColors.sellColor.opacity(0.3), lineWidth: 1)
                )
            }
        }
        .cardStyle()
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    BestRatesView(
        bestBuy: BankRateViewModel(name: "PrivatBank", buyRate: 38.5, sellRate: 39.2, timestamp: ""),
        bestSell: BankRateViewModel(name: "Raiffeisen", buyRate: 38.3, sellRate: 38.9, timestamp: "")
    )
    .padding()
    .background(AppColors.groupedBackground)
}
