//
//  DetailedInfoView.swift
//  CurrEx
//
//  Created for CurrEx on 05.03.2025.
//

import SwiftUI

/// View showing detailed exchange rates for all banks
struct DetailedInfoView: View {
    let rates: [BankRateViewModel]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Detailed Information")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.text)
            
            VStack(spacing: 0) {
                // Table header
                HStack {
                    Text("Bank")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(AppColors.text)
                    
                    Text("Buy")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(width: 70, alignment: .trailing)
                        .foregroundColor(AppColors.text)
                    
                    Text("Sell")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(width: 70, alignment: .trailing)
                        .foregroundColor(AppColors.text)
                    
                    Text("Spread")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(width: 70, alignment: .trailing)
                        .foregroundColor(AppColors.text)
                }
                .padding(.vertical, 10)
                .padding(.horizontal)
                .background(AppColors.secondaryBackground)
                
                // Table rows
                ForEach(rates) { rate in
                    HStack {
                        Text(rate.name)
                            .font(.subheadline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(AppColors.text)
                        
                        Text(String(format: "%.2f", rate.buyRate))
                            .font(.subheadline)
                            .frame(width: 70, alignment: .trailing)
                            .foregroundColor(AppColors.buyColor)
                        
                        Text(String(format: "%.2f", rate.sellRate))
                            .font(.subheadline)
                            .frame(width: 70, alignment: .trailing)
                            .foregroundColor(AppColors.sellColor)
                        
                        Text(String(format: "%.2f", rate.spread))
                            .font(.subheadline)
                            .frame(width: 70, alignment: .trailing)
                            .foregroundColor(AppColors.secondaryText)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal)
                    .background(AppColors.background)
                    .overlay(
                        Divider()
                            .background(AppColors.dividerColor)
                            .offset(y: 20),
                        alignment: .bottom
                    )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(AppColors.dividerColor, lineWidth: 1)
            )
        }
        .cardStyle()
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    DetailedInfoView(
        rates: [
            BankRateViewModel(name: "PrivatBank", buyRate: 38.5, sellRate: 39.2, timestamp: ""),
            BankRateViewModel(name: "Raiffeisen", buyRate: 38.3, sellRate: 38.9, timestamp: ""),
            BankRateViewModel(name: "Bestobmin", buyRate: 38.7, sellRate: 39.1, timestamp: "")
        ]
    )
    .padding()
    .background(AppColors.groupedBackground)
    .preferredColorScheme(.dark) // Preview in dark mode
}
