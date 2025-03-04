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
        VStack {
            Chart {
                ForEach(Array(visibleBanks), id: \.self) { bank in
                    // Only show buy rates (separate from sell rates)
                    ForEach(historicalData) { dataPoint in
                        if let bankRate = dataPoint.bankRates[bank], bankRate.buy > 0 {
                            LineMark(
                                x: .value("Дата", dataPoint.date),
                                y: .value("Курс", bankRate.buy)
                            )
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
                                x: .value("Дата", dataPoint.date),
                                y: .value("Курс", bankRate.sell)
                            )
                            .foregroundStyle(by: .value("Bank Sell", "\(bank) (Sell)"))
                            .symbol {
                                Circle()
                                    .stroke(colors[bank, default: .gray], lineWidth: 2)
                                    .frame(width: 5, height: 5)
                            }
                            .interpolationMethod(.linear) // Change to straight lines
                            .lineStyle(StrokeStyle(lineWidth: 2, dash: [4, 2]))
                            .opacity(0.7)
                            .foregroundStyle(colors[bank, default: .gray])
                        }
                    }
                }
                
                if let selectedPoint = selectedDataPoint,
                   let selectedBankName = selectedBank,
                   let bankRate = selectedPoint.bankRates[selectedBankName] {
                    let rateValue = isShowingSellRate ? bankRate.sell : bankRate.buy
                    
                    PointMark(
                        x: .value("Дата", selectedPoint.date),
                        y: .value("Курс", rateValue)
                    )
                    .foregroundStyle(.white)
                    .symbolSize(CGSize(width: 12, height: 12))
                    .annotation(position: .top) {
                        VStack(alignment: .center, spacing: 4) {
                            Text(selectedBankName)
                                .font(.caption)
                                .fontWeight(.bold)
                            
                            Text(String(format: "%.2f ₴", rateValue))
                                .font(.caption)
                                .fontWeight(.bold)
                                
                            Text(selectedPoint.date, format: .dateTime.day().month().year())
                                .font(.caption2)
                        }
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white)
                                .shadow(radius: 2)
                        )
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
