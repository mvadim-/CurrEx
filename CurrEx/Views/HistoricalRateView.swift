//
//  HistoricalRateView.swift
//  CurrEx
//
//  Created for CurrEx on 05.03.2025.
//

import SwiftUI

/// View for displaying historical exchange rate data
struct HistoricalRateView: View {
    @StateObject private var viewModel: HistoricalRatesViewModel
    @Environment(\.presentationMode) var presentationMode
    let currency: CurrencyType
    
    /// Initializes the view with a currency type
    /// - Parameters:
    ///   - currency: Currency to display historical data for
    ///   - viewModel: Optional view model to use
    init(currency: CurrencyType, viewModel: HistoricalRatesViewModel = HistoricalRatesViewModel()) {
        self.currency = currency
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        ZStack {
            AppColors.groupedBackground.edgesIgnoringSafeArea(.all)
            
            if viewModel.isLoading {
                LoadingView()
            } else if let error = viewModel.errorMessage {
                ErrorView(message: error) {
                    viewModel.loadData()
                }
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        PeriodSelectorView(selectedPeriod: $viewModel.selectedPeriod) {
                            viewModel.loadData()
                        }
                        
                        LegendView(
                            visibleBanks: viewModel.visibleBanks,
                            toggleAction: { bank in
                                viewModel.toggleBank(bank)
                            }
                        )
                        
                        if !viewModel.historicalData.isEmpty {
                            HistoricalChartView(
                                historicalData: viewModel.historicalData,
                                visibleBanks: viewModel.visibleBanks,
                                yDomain: viewModel.getYDomain()
                            )
                            
                            Text("Period: \(viewModel.getDateRange())")
                                .font(.caption)
                                .foregroundColor(AppColors.secondaryText)
                                .padding(.horizontal)
                        } else {
                            Text("No data available for the selected period")
                                .font(.subheadline)
                                .foregroundColor(AppColors.secondaryText)
                                .padding()
                                .cardStyle()
                        }
                        
                        DisclaimerView()
                    }
                    .padding()
                }
                .refreshable {
                    viewModel.loadData()
                }
            }
        }
        .navigationTitle("Historical \(currency.displayName) Rates")
        .onAppear {
            viewModel.selectedCurrency = currency
            viewModel.loadData()
        }
    }
}

/// Period selector component for historical data
struct PeriodSelectorView: View {
    @Binding var selectedPeriod: PeriodType
    let loadAction: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Period")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.text)
            
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
                                .background(selectedPeriod == period ? AppColors.accentColor : AppColors.secondaryBackground)
                                .foregroundColor(selectedPeriod == period ? .white : AppColors.text)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .cardStyle()
    }
}

/// Bank selection legend for historical charts
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
            Text("Banks")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.text)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(["Bestobmin", "PrivatBank", "Raiffeisen"], id: \.self) { bank in
                    Button(action: { toggleAction(bank) }) {
                        HStack(spacing: 8) {
                            Image(systemName: visibleBanks.contains(bank) ? "checkmark.square.fill" : "square")
                                .foregroundColor(visibleBanks.contains(bank) ? colors[bank, default: .gray] : AppColors.secondaryText)
                            
                            Text(bank)
                                .foregroundColor(AppColors.text)
                            
                            Spacer()
                            
                            HStack(spacing: 8) {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(colors[bank, default: .gray])
                                        .frame(width: 8, height: 8)
                                    Text("Buy")
                                        .font(.caption)
                                        .foregroundColor(AppColors.secondaryText)
                                }
                                
                                HStack(spacing: 4) {
                                    Circle()
                                        .stroke(colors[bank, default: .gray], lineWidth: 2)
                                        .frame(width: 8, height: 8)
                                    Text("Sell")
                                        .font(.caption)
                                        .foregroundColor(AppColors.secondaryText)
                                }
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    if bank != "Raiffeisen" {
                        Divider()
                            .background(AppColors.dividerColor)
                    }
                }
            }
            .padding()
            .background(AppColors.secondaryBackground)
            .cornerRadius(8)
        }
        .cardStyle()
    }
}

#Preview {
    NavigationView {
        HistoricalRateView(currency: .usd)
    }
}
