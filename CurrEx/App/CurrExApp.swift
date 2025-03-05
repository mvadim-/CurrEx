//
//  CurrExApp.swift
//  CurrEx
//
//  Created by Vadym Maslov on 26.02.2025.
//

import SwiftUI

/// Service container for dependency injection
class ServiceContainer {
    static let shared = ServiceContainer()
    
    /// Exchange rates API service for current rates
    lazy var exchangeRatesService: ExchangeRatesServiceProtocol = ExchangeRatesService()
    
    /// Exchange rates API service for historical data
    lazy var historicalExchangeRatesService: HistoricalExchangeRatesServiceProtocol = HistoricalExchangeRatesService()
    
    private init() {}
}

// MARK: - App Entry Point
@main
struct CurrExApp: App {
    init() {
        // Configure app with settings and localization
        configureApp()
    }
    
    var body: some Scene {
        WindowGroup {
            ExchangeRateView(
                viewModel: ExchangeRateViewModel(
                    service: ServiceContainer.shared.exchangeRatesService
                )
            )
            .preferredColorScheme(.none) // Respect system color scheme
        }
    }
}
