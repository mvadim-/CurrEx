//
//  HistoricalChartView.swift
//  CurrEx
//

import SwiftUI
import Charts

struct HistoricalChartView: View {
    let historicalData: [HistoricalRateDataPoint]
    let visibleBanks: Set<String>
    let yDomain: ClosedRange<Double>
    
    private let colors: [String: Color] = [
        "Bestobmin": .green,
        "PrivatBank": .blue,
        "Raiffeisen": .orange
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Історія курсів")
                .font(.headline)
                .fontWeight(.semibold)
            
            if #available(iOS 16.0, *) {
                modernChartView
            } else {
                legacyChartView
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    @available(iOS 16.0, *)
    private var modernChartView: some View {
        Chart {
            ForEach(historicalData) { dataPoint in
                ForEach(Array(visibleBanks), id: \.self) { bank in
                    // Only draw if the bank has data for this point
                    if let bankRate = dataPoint.bankRates[bank], bankRate.buy > 0 {
                        LineMark(
                            x: .value("Дата", dataPoint.date),
                            y: .value("Курс", bankRate.buy)
                        )
                        .foregroundStyle(colors[bank, default: .gray])
                        .symbol {
                            Circle()
                                .fill(colors[bank, default: .gray])
                                .frame(width: 5, height: 5)
                        }
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: []))
                        .opacity(0.7)
                        .annotation(position: .top) {
                            if dataPoint.id == historicalData.last?.id {
                                Text(String(format: "%.2f ₴", bankRate.buy))
                                    .font(.caption2)
                                    .foregroundColor(colors[bank, default: .gray])
                            }
                        }
                    }
                    
                    if let bankRate = dataPoint.bankRates[bank], bankRate.sell > 0 {
                        LineMark(
                            x: .value("Дата", dataPoint.date),
                            y: .value("Курс", bankRate.sell)
                        )
                        .foregroundStyle(colors[bank, default: .gray])
                        .symbol {
                            Circle()
                                .stroke(colors[bank, default: .gray], lineWidth: 2)
                                .frame(width: 5, height: 5)
                        }
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [4, 2]))
                        .opacity(0.7)
                        .annotation(position: .top) {
                            if dataPoint.id == historicalData.last?.id {
                                Text(String(format: "%.2f ₴", bankRate.sell))
                                    .font(.caption2)
                                    .foregroundColor(colors[bank, default: .gray])
                            }
                        }
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(date, format: .dateTime.day().month())
                            .font(.caption)
                    }
                }
            }
        }
        .chartYScale(domain: yDomain)
        .frame(height: 300)
        .chartLegend(.hidden)
    }
    
    private var legacyChartView: some View {
        VStack(spacing: 16) {
            Text("Графік історії курсів доступний в iOS 16+")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            if let firstDataPoint = historicalData.first, let lastDataPoint = historicalData.last {
                VStack(spacing: 12) {
                    Text("Початковий курс:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    ForEach(Array(visibleBanks), id: \.self) { bank in
                        if let bankRate = firstDataPoint.bankRates[bank] {
                            HStack {
                                Text(bank)
                                    .font(.subheadline)
                                
                                Spacer()
                                
                                VStack(alignment: .trailing) {
                                    Text("Купівля: \(String(format: "%.2f", bankRate.buy)) ₴")
                                    Text("Продаж: \(String(format: "%.2f", bankRate.sell)) ₴")
                                }
                                .font(.caption)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    Text("Останній курс:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(.top, 8)
                    
                    ForEach(Array(visibleBanks), id: \.self) { bank in
                        if let bankRate = lastDataPoint.bankRates[bank] {
                            HStack {
                                Text(bank)
                                    .font(.subheadline)
                                
                                Spacer()
                                
                                VStack(alignment: .trailing) {
                                    Text("Купівля: \(String(format: "%.2f", bankRate.buy)) ₴")
                                    Text("Продаж: \(String(format: "%.2f", bankRate.sell)) ₴")
                                }
                                .font(.caption)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(8)
            }
        }
    }
}

struct LegendView: View {
    let visibleBanks: Set<String>
    let toggleAction: (String) -> Void
    
    private let colors: [String: Color] = [
        "Bestobmin": .green,
        "PrivatBank": .blue,
        "Raiffeisen": .orange
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Банки")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(["Bestobmin", "PrivatBank", "Raiffeisen"], id: \.self) { bank in
                    Button(action: { toggleAction(bank) }) {
                        HStack(spacing: 8) {
                            Image(systemName: visibleBanks.contains(bank) ? "checkmark.square.fill" : "square")
                                .foregroundColor(visibleBanks.contains(bank) ? colors[bank, default: .gray] : .gray)
                            
                            Text(bank)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            HStack(spacing: 8) {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(colors[bank, default: .gray])
                                        .frame(width: 8, height: 8)
                                    Text("Купівля")
                                        .font(.caption)
                                }
                                
                                HStack(spacing: 4) {
                                    Circle()
                                        .stroke(colors[bank, default: .gray], lineWidth: 2)
                                        .frame(width: 8, height: 8)
                                    Text("Продаж")
                                        .font(.caption)
                                }
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    if bank != "Raiffeisen" {
                        Divider()
                    }
                }
            }
            .padding()
            .background(Color(UIColor.systemGray6))
            .cornerRadius(8)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct PeriodSelectorView: View {
    @Binding var selectedPeriod: PeriodType
    let loadAction: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Період")
                .font(.headline)
                .fontWeight(.semibold)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(PeriodType.allCases) { period in
                        Button(action: {
                            selectedPeriod = period
                            loadAction()
                        }) {
                            Text(period.displayName)
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(selectedPeriod == period ? Color.blue : Color(UIColor.systemGray6))
                                .foregroundColor(selectedPeriod == period ? .white : .primary)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
