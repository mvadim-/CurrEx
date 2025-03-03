//
//  HistoricalRateView.swift
//  CurrEx
//

import SwiftUI

struct HistoricalRateView: View {
    @StateObject private var viewModel = HistoricalRatesViewModel()
    @Environment(\.presentationMode) var presentationMode
    let currency: CurrencyType
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGray6).edgesIgnoringSafeArea(.all)
            
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
                            
                            Text("Період: \(viewModel.getDateRange())")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                        } else {
                            Text("Немає даних для відображення за обраний період")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .padding()
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
        .navigationTitle("Історія курсу \(currency.displayName)")
        .onAppear {
            viewModel.selectedCurrency = currency
            viewModel.loadData()
        }
    }
}

#Preview {
    NavigationView {
        HistoricalRateView(currency: .usd)
    }
}
