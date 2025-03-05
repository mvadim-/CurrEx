//
//  HistoricalChartView.swift
//  CurrEx
//
//  Created for CurrEx on 05.03.2025.
//

import SwiftUI
import Charts

/// Chart view for displaying historical exchange rates
struct HistoricalChartView: View {
    let historicalData: [HistoricalRateDataPoint]
    let visibleBanks: Set<String>
    let yDomain: ClosedRange<Double>
    
    @State private var selectedDataPoint: HistoricalRateDataPoint?
    @State private var selectedBank: String?
    @State private var isShowingSellRate: Bool = false
    
    private let colors: [String: Color] = [
        "Bestobmin": .green,
        "PrivatBank": .blue,
        "Raiffeisen": .orange
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Rate History")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.text)
            
            if #available(iOS 16.0, *) {
                modernChartView
            } else {
                legacyChartView
            }
        }
        .cardStyle()
    }
    
    /// Modern chart view using the Charts framework (iOS 16+)
    @available(iOS 16.0, *)
    private var modernChartView: some View {
        VStack {
            Chart {
                ForEach(Array(visibleBanks), id: \.self) { bank in
                    // Only show buy rates (separate from sell rates)
                    ForEach(historicalData) { dataPoint in
                        if let bankRate = dataPoint.bankRates[bank], bankRate.buy > 0 {
                            LineMark(
                                x: .value("Date", dataPoint.date),
                                y: .value("Rate", bankRate.buy)
                            )
                            .foregroundStyle(colors[bank, default: .gray])
                            .foregroundStyle(by: .value("Bank Buy", "\(bank) (Buy)"))
                            .symbol {
                                Circle()
                                    .fill(colors[bank, default: .gray])
                                    .frame(width: 5, height: 5)
                            }
                            .interpolationMethod(.linear) // Change to straight lines
                            .lineStyle(StrokeStyle(lineWidth: 2, dash: []))
                            .opacity(0.7)
                            .foregroundStyle(colors[bank, default: .gray])
                        }
                    }
                    
                    // Separate loop for sell rates
                    ForEach(historicalData) { dataPoint in
                        if let bankRate = dataPoint.bankRates[bank], bankRate.sell > 0 {
                            LineMark(
                                x: .value("Date", dataPoint.date),
                                y: .value("Rate", bankRate.sell)
                            )
                            .foregroundStyle(colors[bank, default: .gray])
                            .foregroundStyle(by: .value("Bank Sell", "\(bank) (Sell)"))
                            .symbol {
                                Circle()
                                    .stroke(colors[bank, default: .gray], lineWidth: 2)
                                    .frame(width: 5, height: 5)
                            }
                            .interpolationMethod(.linear) // Change to straight lines
                            .lineStyle(StrokeStyle(lineWidth: 2, dash: [4, 2]))
                            .opacity(0.7)
                        }
                    }
                }
                
                if let selectedPoint = selectedDataPoint,
                   let selectedBankName = selectedBank,
                   let bankRate = selectedPoint.bankRates[selectedBankName] {
                    let rateValue = isShowingSellRate ? bankRate.sell : bankRate.buy
                    
                    PointMark(
                        x: .value("Date", selectedPoint.date),
                        y: .value("Rate", rateValue)
                    )
                    .foregroundStyle(.gray.opacity(0.7))
                    .symbolSize(CGSize(width: 12, height: 12))
                    .annotation(position: .top) {
                        VStack(alignment: .center, spacing: 4) {
                            Text(selectedBankName)
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(AppColors.text)
                            
                            Text(String(format: "%.2f ₴", rateValue))
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(AppColors.text)
                                
                            Text(selectedPoint.date, format: .dateTime.day().month().year())
                                .font(.caption2)
                                .foregroundColor(AppColors.secondaryText)
                        }
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(AppColors.background)
                                .shadow(radius: 2)
                        )
                    }
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisGridLine()
                        .foregroundStyle(AppColors.dividerColor.opacity(0.5))
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(date, format: .dateTime.day().month())
                                .font(.caption)
                                .foregroundColor(AppColors.secondaryText)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [5, 5]))
                        .foregroundStyle(AppColors.dividerColor.opacity(0.5))
                    AxisValueLabel {
                        if let doubleValue = value.as(Double.self) {
                            Text(String(format: "%.1f", doubleValue))
                                .foregroundColor(AppColors.secondaryText)
                        }
                    }
                }
            }
            .chartYScale(domain: yDomain)
            .frame(height: 300)
            .chartLegend(.hidden)
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let xPosition = value.location.x
                                    let yPosition = value.location.y
                                    
                                    // Find the closest point to the tap location
                                    findClosestDataPoint(at: xPosition, y: yPosition, in: proxy, with: geometry)
                                }
                                .onEnded { _ in
                                    // Keep the selected point visible
                                }
                        )
                }
            }
        }
    }
    
    /// Helper method to find closest data point to the tap location
    @available(iOS 16.0, *)
    private func findClosestDataPoint(at xPosition: CGFloat, y yPosition: CGFloat, in proxy: ChartProxy, with geometry: GeometryProxy) {
        guard !historicalData.isEmpty, !visibleBanks.isEmpty else { return }
        
        // Convert the tap position to a date using the ChartProxy
        guard let date = proxy.value(atX: xPosition, as: Date.self) else { return }
        
        // Find the closest data point to the date
        let closestPoint = historicalData.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) })
        
        guard let closestDataPoint = closestPoint else { return }
        
        // Convert the tap y-position to a rate value
        guard let tappedRate = proxy.value(atY: yPosition, as: Double.self) else { return }
        
        // Find the bank and whether it's buy or sell rate that is closest to the tap
        var closestBank: String? = nil
        var closestDistance = Double.infinity
        var isSellRate = false
        
        for bank in visibleBanks {
            if let rates = closestDataPoint.bankRates[bank] {
                let buyDistance = abs(rates.buy - tappedRate)
                let sellDistance = abs(rates.sell - tappedRate)
                
                if buyDistance < closestDistance {
                    closestDistance = buyDistance
                    closestBank = bank
                    isSellRate = false
                }
                
                if sellDistance < closestDistance {
                    closestDistance = sellDistance
                    closestBank = bank
                    isSellRate = true
                }
            }
        }
        
        selectedDataPoint = closestDataPoint
        selectedBank = closestBank
        isShowingSellRate = isSellRate
    }
    
    /// Legacy chart view for iOS versions earlier than 16
    private var legacyChartView: some View {
        VStack(spacing: 16) {
            Text("Chart history is available in iOS 16+")
                .font(.caption)
                .foregroundColor(AppColors.secondaryText)
                .multilineTextAlignment(.center)
            
            if let firstDataPoint = historicalData.first, let lastDataPoint = historicalData.last {
                VStack(spacing: 12) {
                    Text("Initial rates:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.text)
                    
                    ForEach(Array(visibleBanks), id: \.self) { bank in
                        if let bankRate = firstDataPoint.bankRates[bank] {
                            HStack {
                                Text(bank)
                                    .font(.subheadline)
                                    .foregroundColor(AppColors.text)
                                
                                Spacer()
                                
                                VStack(alignment: .trailing) {
                                    Text("Buy: \(String(format: "%.2f", bankRate.buy)) ₴")
                                        .foregroundColor(AppColors.buyColor)
                                    Text("Sell: \(String(format: "%.2f", bankRate.sell)) ₴")
                                        .foregroundColor(AppColors.sellColor)
                                }
                                .font(.caption)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    Text("Latest rates:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.text)
                        .padding(.top, 8)
                    
                    ForEach(Array(visibleBanks), id: \.self) { bank in
                        if let bankRate = lastDataPoint.bankRates[bank] {
                            HStack {
                                Text(bank)
                                    .font(.subheadline)
                                    .foregroundColor(AppColors.text)
                                
                                Spacer()
                                
                                VStack(alignment: .trailing) {
                                    Text("Buy: \(String(format: "%.2f", bankRate.buy)) ₴")
                                        .foregroundColor(AppColors.buyColor)
                                    Text("Sell: \(String(format: "%.2f", bankRate.sell)) ₴")
                                        .foregroundColor(AppColors.sellColor)
                                }
                                .font(.caption)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .padding()
                .background(AppColors.secondaryBackground)
                .cornerRadius(8)
            }
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    let date = Date()
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    
    let sampleData = [
        HistoricalRateDataPoint(
            date: date.addingTimeInterval(-86400 * 4),
            bankRates: [
                "PrivatBank": (buy: 38.5, sell: 39.2),
                "Raiffeisen": (buy: 38.3, sell: 38.9),
                "Bestobmin": (buy: 38.7, sell: 39.1)
            ]
        ),
        HistoricalRateDataPoint(
            date: date.addingTimeInterval(-86400 * 3),
            bankRates: [
                "PrivatBank": (buy: 38.6, sell: 39.3),
                "Raiffeisen": (buy: 38.4, sell: 39.0),
                "Bestobmin": (buy: 38.8, sell: 39.2)
            ]
        ),
        HistoricalRateDataPoint(
            date: date.addingTimeInterval(-86400 * 2),
            bankRates: [
                "PrivatBank": (buy: 38.7, sell: 39.4),
                "Raiffeisen": (buy: 38.5, sell: 39.1),
                "Bestobmin": (buy: 38.9, sell: 39.3)
            ]
        ),
        HistoricalRateDataPoint(
            date: date.addingTimeInterval(-86400),
            bankRates: [
                "PrivatBank": (buy: 38.8, sell: 39.5),
                "Raiffeisen": (buy: 38.6, sell: 39.2),
                "Bestobmin": (buy: 39.0, sell: 39.4)
            ]
        ),
        HistoricalRateDataPoint(
            date: date,
            bankRates: [
                "PrivatBank": (buy: 38.9, sell: 39.6),
                "Raiffeisen": (buy: 38.7, sell: 39.3),
                "Bestobmin": (buy: 39.1, sell: 39.5)
            ]
        )
    ]
    
    return HistoricalChartView(
        historicalData: sampleData,
        visibleBanks: ["PrivatBank", "Raiffeisen", "Bestobmin"],
        yDomain: 38...40
    )
    .padding()
    .background(AppColors.groupedBackground)
}
