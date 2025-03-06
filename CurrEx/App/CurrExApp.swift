//
//  CurrExApp.swift
//  CurrEx
//
//  Created by Vadym Maslov on 26.02.2025.
//

import SwiftUI
import WidgetKit

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
    @Environment(\.scenePhase) private var scenePhase
    
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
            .preferredColorScheme(.none)
            .onOpenURL { url in
                handleDeepLink(url)
            }
        }
        .onChange(of: scenePhase) {oldPhase, newPhase in
            if newPhase == .active {
                // Оновлюємо дані при поверненні в активний режим
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }
    
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "currex" else { return }
        
        // Визначаємо, яку дію здійснити на основі URL
        if url.host == "widget" && url.path == "/rates" {
            // Просто відкриваємо додаток
            // Тут можна додати логіку для переходу на конкретний екран
        }
    }
}
