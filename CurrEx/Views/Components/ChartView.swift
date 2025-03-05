//
//  ChartView.swift
//  CurrEx
//
//  Created for CurrEx on 05.03.2025.
//

import SwiftUI
import Charts

/// Chart view for displaying exchange rates
struct RateChartView: View {
    let rates: [BankRateViewModel]
    let yDomain: ClosedRange<Double>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("Rate Comparison", comment: "Rate comparison section title"))
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
        Chart {
            ForEach(rates) { rate in
                BarMark(
                    x: .value(NSLocalizedString("Bank", comment: "Chart bank label"), rate.name),
                    y: .value(NSLocalizedString("Rate", comment: "Chart rate label"), rate.buyRate)
                )
                .foregroundStyle(AppColors.buyColor)
                .position(by: .value("Type", NSLocalizedString("Buy", comment: "Buy rate type")), axis: .horizontal)
                .annotation(position: .top) {
                    Text(String(format: "%.2f", rate.buyRate))
                        .font(.caption2)
                        .foregroundColor(AppColors.text)
                }

                BarMark(
                    x: .value(NSLocalizedString("Bank", comment: "Chart bank label"), rate.name),
                    y: .value(NSLocalizedString("Rate", comment: "Chart rate label"), rate.sellRate)
                )
                .foregroundStyle(AppColors.sellColor)
                .position(by: .value("Type", NSLocalizedString("Sell", comment: "Sell rate type")), axis: .horizontal)
                .annotation(position: .top) {
                    Text(String(format: "%.2f", rate.sellRate))
                        .font(.caption2)
                        .foregroundColor(AppColors.text)
                }
            }
        }
        .chartPlotStyle { plotArea in
            plotArea.padding(.bottom, 30)
        }
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let label = value.as(String.self) {
                        Text(label)
                            .rotationEffect(.degrees(-90))
                            .offset(x: 0, y: 8)
                            .foregroundColor(AppColors.text)
                    }
                }
                AxisTick()
                AxisGridLine()
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let doubleValue = value.as(Double.self) {
                        Text(String(format: "%.1f", doubleValue))
                            .foregroundColor(AppColors.secondaryText)
                    }
                }
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [5, 5]))
                    .foregroundStyle(AppColors.dividerColor.opacity(0.5))
            }
        }
        .frame(height: 250)
        .chartYScale(domain: yDomain)
        .chartLegend(position: .top, alignment: .center)
    }
    
    /// Legacy chart view for iOS versions earlier than 16
    private var legacyChartView: some View {
        VStack(spacing: 16) {
            Text(NSLocalizedString("Chart view is available in iOS 16+", comment: "Legacy chart message"))
                .font(.caption)
                .foregroundColor(AppColors.secondaryText)
                .multilineTextAlignment(.center)
            
            HStack(alignment: .bottom, spacing: 12) {
                ForEach(rates) { rate in
                    VStack(spacing: 4) {
                        VStack {
                            Spacer()
                            Text(String(format: "%.2f", rate.sellRate))
                                .font(.caption2)
                                .foregroundColor(.white)
                                .rotationEffect(.degrees(-90))
                                .padding(.vertical, 2)
                        }
                        .frame(width: 30, height: CGFloat(rate.sellRate * 5))
                        .background(AppColors.sellColor)
                        .cornerRadius(4)
                        
                        VStack {
                            Spacer()
                            Text(String(format: "%.2f", rate.buyRate))
                                .font(.caption2)
                                .foregroundColor(.white)
                                .rotationEffect(.degrees(-90))
                                .padding(.vertical, 2)
                        }
                        .frame(width: 30, height: CGFloat(rate.buyRate * 5))
                        .background(AppColors.buyColor)
                        .cornerRadius(4)
                        
                        Text(rate.name)
                            .font(.caption)
                            .foregroundColor(AppColors.text)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.center)
                            .frame(width: 70)
                    }
                }
            }
            .frame(height: 250)
            
            HStack(spacing: 16) {
                HStack(spacing: 8) {
                    Rectangle()
                        .fill(AppColors.buyColor)
                        .frame(width: 12, height: 12)
                    Text(NSLocalizedString("Buy", comment: "Buy legend label"))
                        .font(.caption)
                        .foregroundColor(AppColors.text)
                }
                
                HStack(spacing: 8) {
                    Rectangle()
                        .fill(AppColors.sellColor)
                        .frame(width: 12, height: 12)
                    Text(NSLocalizedString("Sell", comment: "Sell legend label"))
                        .font(.caption)
                        .foregroundColor(AppColors.text)
                }
            }
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    RateChartView(
        rates: [
            BankRateViewModel(name: "PrivatBank", buyRate: 38.5, sellRate: 39.2, timestamp: ""),
            BankRateViewModel(name: "Raiffeisen", buyRate: 38.3, sellRate: 38.9, timestamp: ""),
            BankRateViewModel(name: "Bestobmin", buyRate: 38.7, sellRate: 39.1, timestamp: "")
        ],
        yDomain: 38...40
    )
    .padding()
    .background(AppColors.groupedBackground)
}
