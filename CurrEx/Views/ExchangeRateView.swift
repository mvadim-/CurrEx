//
//  ExchangeRateView.swift
//  CurrEx
//

import SwiftUI

// MARK: - Main View
struct ExchangeRateView: View {
    @StateObject private var viewModel = ExchangeRateViewModel()
    @State private var currentTab = 0
    @State private var showingHistoricalView = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGray6).edgesIgnoringSafeArea(.all)
                
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
            .navigationTitle("Курс валют в Україні")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingHistoricalView = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                            Text("Історія")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingHistoricalView) {
                NavigationView {
                    HistoricalRateView(currency: viewModel.selectedCurrency)
                        .navigationBarItems(trailing: Button("Закрити") {
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
    
    private func currencyView(for currency: CurrencyType) -> some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                HStack {
                    Text("Валюта: \(currency.displayName)")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button(action: {
                        showingHistoricalView = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                            Text("Історія")
                        }
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
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

#Preview {
    ExchangeRateView()
}
