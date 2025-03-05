//
//  SettingsManager.swift
//  CurrEx
//
//  Created for CurrEx on 05.03.2025.
//

import Foundation
import SwiftUI

/// Class for managing app settings and preferences
final class SettingsManager: ObservableObject {
    // MARK: - Static Properties
    
    /// Shared instance for app-wide access
    static let shared = SettingsManager()
    
    // MARK: - Published Properties
    
    /// Currently selected app language
    @Published var selectedLanguage: Language {
        didSet {
            saveSelectedLanguage()
            applyLanguageSettings()
        }
    }
    
    // MARK: - Private Properties
    
    /// UserDefaults keys
    private enum UserDefaultsKeys {
        static let selectedLanguage = "selectedLanguage"
    }
    
    // MARK: - Initialization
    
    private init() {
        // Load saved language or default to system language
        if let savedLanguageRawValue = UserDefaults.standard.string(forKey: UserDefaultsKeys.selectedLanguage),
           let savedLanguage = Language(rawValue: savedLanguageRawValue) {
            self.selectedLanguage = savedLanguage
        } else {
            // Default to Ukrainian or use system language if available
            let preferredLanguage = Locale.preferredLanguages.first ?? ""
            if preferredLanguage.starts(with: "uk") {
                self.selectedLanguage = .ukrainian
            } else {
                self.selectedLanguage = .english
            }
        }
        
        // Apply the loaded language settings
        applyLanguageSettings()
    }
    
    // MARK: - Private Methods
    
    /// Save the selected language to UserDefaults
    private func saveSelectedLanguage() {
        UserDefaults.standard.set(selectedLanguage.rawValue, forKey: UserDefaultsKeys.selectedLanguage)
    }
    
    /// Apply the selected language to the app
    private func applyLanguageSettings() {
        // Set the app's locale based on the selected language
        UserDefaults.standard.set([selectedLanguage.rawValue], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        
        // Note: For a complete language change, app restart is typically required
        // But the following can help with some immediate changes
        let locale = Locale(identifier: selectedLanguage.localeIdentifier)
        
        // Force update date formatters
        Formatters.updateLocale(to: locale)
        
        // Post notification for views to refresh
        NotificationCenter.default.post(name: Notification.Name("LanguageChanged"), object: nil)
    }
}
