//
//  ExchangeRateView.swift
//  CurrEx
//
//  Created for CurrEx on 05.03.2025.
//

import SwiftUI

// MARK: - Main View
struct ExchangeRateView: View {
    @StateObject private var viewModel: ExchangeRateViewModel
    @State private var currentTab = 0
    @State private var showingHistoricalView = false
    
    /// Initializes the view with a view model
    /// - Parameter viewModel: View model for exchange rates
    init(viewModel: ExchangeRateViewModel = ExchangeRateViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.groupedBackground.edgesIgnoringSafeArea(.all)
                
                if viewModel.isLoading {
                    LoadingView()
                } else if let error = viewModel.errorMessage {
                    ErrorView(message: error) {
                        viewModel.loadDataForAllCurrencies()
                    }
                } else {
                    mainContentView
                }
            }
            .navigationTitle("Exchange Rates in IF")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingHistoricalView = true
                    }) {
//                        HStack(spacing: 4) {
//                            Image(systemName: "chart.line.uptrend.xyaxis")
//                            Text("History")
//                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        viewModel.loadDataForAllCurrencies()
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .sheet(isPresented: $showingHistoricalView) {
                NavigationView {
                    HistoricalRateView(currency: viewModel.selectedCurrency)
                        .navigationBarItems(trailing: Button("Close") {
                            showingHistoricalView = false
                        })
                }
            }
        }
        .onAppear {
            viewModel.loadDataForAllCurrencies()
        }
    }
    
    // MARK: - Subviews
    private var mainContentView: some View {
        VStack {
            if #available(iOS 17.0, *) {
                TabView(selection: $currentTab) {
                    currencyView(for: .usd)
                        .tag(0)
                    
                    currencyView(for: .eur)
                        .tag(1)
                }
                .tabViewStyle(PageTabViewStyle())
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                .onChange(of: currentTab) {
                    viewModel.selectedCurrency = currentTab == 0 ? .usd : .eur
                }
            } else {
                TabView(selection: $currentTab) {
                    currencyView(for: .usd)
                        .tag(0)
                    
                    currencyView(for: .eur)
                        .tag(1)
                }
                .tabViewStyle(PageTabViewStyle())
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                .onChange(of: currentTab) { newValue in
                    viewModel.selectedCurrency = newValue == 0 ? .usd : .eur
                }
            }
        }
    }
    
    private func currencyView(for currency: CurrencyType) -> some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                HStack {
                    Text("Currency: \(currency.displayName)")
                        .font(.headline)
                        .foregroundColor(AppColors.text)
                    
                    Spacer()
                    
                    Button(action: {
                        showingHistoricalView = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                            Text("History")
                        }
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AppColors.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                .padding(.vertical, 8)
                
                LastUpdatedView(timestamp: viewModel.getLastUpdatedFromServer(for: currency))
                
                let bestRates = viewModel.findBestRates(for: currency)
                BestRatesView(bestBuy: bestRates.buy, bestSell: bestRates.sell)
                
                RateChartView(
                    rates: viewModel.getRates(for: currency),
                    yDomain: viewModel.getChartYDomain(for: currency)
                )
                
                DetailedInfoView(rates: viewModel.getRates(for: currency))
                
                DisclaimerView()
            }
            .padding()
        }
        .refreshable {
            viewModel.loadData(for: currency)
        }
    }
}
