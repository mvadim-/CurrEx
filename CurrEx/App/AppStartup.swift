//
//  AppStartup.swift
//  CurrEx
//
//  Created for CurrEx on 05.03.2025.
//

import Foundation
import SwiftUI

// MARK: - App Extension

extension CurrExApp {
    /// Configure the app with initial setup requirements
    func configureApp() {
        // Initialize the settings manager to load language preferences
        _ = SettingsManager.shared
    }
}

// MARK: - Update the App Entry Point

/*
 To implement localization in your app:
 
 1. Update the CurrExApp.swift file to call configureApp() in the init() method:
 
 ```
 @main
 struct CurrExApp: App {
     init() {
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
 ```
 
 2. Add localization to your Xcode project:
    - In Xcode, go to your project settings
    - Select the project in the Project Navigator
    - Go to the "Info" tab
    - In the "Localizations" section, click the "+" button
    - Add Ukrainian (uk) to your project
    
 3. Create Localizable.strings files:
    - Create a new file named "Localizable.strings"
    - Select the file and in the File Inspector, click "Localize..."
    - Select English
    - In the Project Navigator, select the localized file
    - In the File Inspector, check both English and Ukrainian
    - This will create two files where you can add your translations
    
 4. Move the provided Localizable.strings content to their respective files
    - Copy the English strings to the English version
    - Copy the Ukrainian strings to the Ukrainian version
 
 5. Restart the app to see the language changes take effect
 */
