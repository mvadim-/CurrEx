//
//  DetailedInfoView.swift
//  CurrEx
//

import SwiftUI

struct DetailedInfoView: View {
    let rates: [BankRateViewModel]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Детальна інформація")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 0) {
                HStack {
                    Text("Банк")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("Купівля")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(width: 70, alignment: .trailing)
                    
                    Text("Продаж")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(width: 70, alignment: .trailing)
                    
                    Text("Спред")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(width: 70, alignment: .trailing)
                }
                .padding(.vertical, 10)
                .padding(.horizontal)
                .background(Color(UIColor.systemGray5))
                
                ForEach(rates) { rate in
                    HStack {
                        Text(rate.name)
                            .font(.subheadline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text(String(format: "%.2f", rate.buyRate))
                            .font(.subheadline)
                            .frame(width: 70, alignment: .trailing)
                        
                        Text(String(format: "%.2f", rate.sellRate))
                            .font(.subheadline)
                            .frame(width: 70, alignment: .trailing)
                        
                        Text(String(format: "%.2f", rate.spread))
                            .font(.subheadline)
                            .frame(width: 70, alignment: .trailing)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal)
                    .background(Color.white)
                    .overlay(
                        Divider()
                            .background(Color(UIColor.systemGray4))
                            .offset(y: 20),
                        alignment: .bottom
                    )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(UIColor.systemGray4), lineWidth: 1)
            )
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
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
    .background(Color(UIColor.systemGray6))
}
