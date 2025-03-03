//
//  ChartView.swift
//  CurrEx
//

import SwiftUI
import Charts

struct RateChartView: View {
    let rates: [BankRateViewModel]
    let yDomain: ClosedRange<Double>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Порівняння курсів")
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
            ForEach(rates) { rate in
                BarMark(
                    x: .value("Банк", rate.name),
                    y: .value("Курс", rate.buyRate)
                )
                .foregroundStyle(Color.green)
                .position(by: .value("Тип", "Купівля"), axis: .horizontal)
                .annotation(position: .top) {
                    Text(String(format: "%.2f", rate.buyRate))
                        .font(.caption2)
                        .foregroundColor(.black)
                }

                BarMark(
                    x: .value("Банк", rate.name),
                    y: .value("Курс", rate.sellRate)
                )
                .foregroundStyle(Color.blue)
                .position(by: .value("Тип", "Продаж"), axis: .horizontal)
                .annotation(position: .top) {
                    Text(String(format: "%.2f", rate.sellRate))
                        .font(.caption2)
                        .foregroundColor(.black)
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
                    }
                }
                AxisTick()
                AxisGridLine()
            }
        }
        .frame(height: 250)
        .chartYScale(domain: yDomain)
        .chartLegend(position: .top, alignment: .center)
    }
    
    private var legacyChartView: some View {
        VStack(spacing: 16) {
            Text("Курси в графічному вигляді доступні в iOS 16+")
                .font(.caption)
                .foregroundColor(.gray)
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
                        .background(Color.blue)
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
                        .background(Color.green)
                        .cornerRadius(4)
                        
                        Text(rate.name)
                            .font(.caption)
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
                        .fill(Color.green)
                        .frame(width: 12, height: 12)
                    Text("Купівля")
                        .font(.caption)
                }
                
                HStack(spacing: 8) {
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: 12, height: 12)
                    Text("Продаж")
                        .font(.caption)
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
    .background(Color(UIColor.systemGray6))
}
