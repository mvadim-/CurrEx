//
//  BestRatesView.swift
//  CurrEx
//

import SwiftUI

struct BestRatesView: View {
    let bestBuy: BankRateViewModel?
    let bestSell: BankRateViewModel?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Найкращі курси")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Найвигідніше продати у")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    if let bestBuy = bestBuy {
                        Text("\(bestBuy.name): \(String(format: "%.2f", bestBuy.buyRate)) ₴")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.green.opacity(0.1))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Найвигідніше купити у")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    if let bestSell = bestSell {
                        Text("\(bestSell.name): \(String(format: "%.2f", bestSell.sellRate)) ₴")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    BestRatesView(
        bestBuy: BankRateViewModel(name: "PrivatBank", buyRate: 38.5, sellRate: 39.2, timestamp: ""),
        bestSell: BankRateViewModel(name: "Raiffeisen", buyRate: 38.3, sellRate: 38.9, timestamp: "")
    )
    .padding()
    .background(Color(UIColor.systemGray6))
    .previewLayout(.sizeThatFits)
}
