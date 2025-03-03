//
//  CurrExApp.swift
//  CurrEx
//
//  Created by Vadym Maslov on 26.02.2025.
//

import SwiftUI

// MARK: - App Entry Point
@main
struct CurrExApp: App {
    var body: some Scene {
        WindowGroup {
            ExchangeRateView()
                .accentColor(Color.blue)
        }
    }
}
