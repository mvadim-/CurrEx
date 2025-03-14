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
    
    /// Banks that should be visible in the app
    @Published var visibleBanks: Set<String> {
        didSet {
            saveVisibleBanks()
        }
    }
    
    /// All available banks in the system
    @Published var availableBanks: [String] = ["Bestobmin", "PrivatBank", "Raiffeisen"] {
        didSet {
            // Ensure visibleBanks contains only valid bank names
            visibleBanks = visibleBanks.intersection(Set(availableBanks))
            
            // If no visible banks, show all
            if visibleBanks.isEmpty {
                visibleBanks = Set(availableBanks)
                saveVisibleBanks()
            }
            
            // Notify any observers that bank list has changed
            NotificationCenter.default.post(name: Notification.Name("AvailableBanksChanged"), object: nil)
        }
    }
    
    // MARK: - Private Properties
    
    /// UserDefaults keys
    private enum UserDefaultsKeys {
        static let selectedLanguage = "selectedLanguage"
        static let visibleBanks = "visibleBanks"
    }
    
    // MARK: - Initialization
    
    private init() {
        // Initialize with default values
        self.selectedLanguage = .english
        self.visibleBanks = Set(["Bestobmin", "PrivatBank", "Raiffeisen"])
        
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
        
        // Load saved visible banks or default to all banks
        if let savedBanks = UserDefaults.standard.array(forKey: UserDefaultsKeys.visibleBanks) as? [String] {
            self.visibleBanks = Set(savedBanks).intersection(Set(availableBanks))
            
            // Ensure at least one bank is visible
            if self.visibleBanks.isEmpty {
                self.visibleBanks = Set(availableBanks)
            }
        }
        
        // Apply the loaded language settings
        applyLanguageSettings()
    }
    
    // MARK: - Public Methods
    
    /// Updates the list of available banks
    /// - Parameter banks: Array of bank names
    func updateAvailableBanks(_ banks: [String]) {
        // Don't trigger needless updates if the bank list is the same
        guard Set(banks) != Set(availableBanks) else { return }
        availableBanks = banks
    }
    
    /// Toggles visibility of a bank
    /// - Parameter bankName: Name of the bank to toggle
    func toggleBankVisibility(_ bankName: String) {
        if visibleBanks.contains(bankName) {
            // Don't allow hiding the last visible bank
            if visibleBanks.count > 1 {
                visibleBanks.remove(bankName)
            }
        } else {
            visibleBanks.insert(bankName)
        }
    }
    
    /// Checks if a bank is visible
    /// - Parameter bankName: Name of the bank to check
    /// - Returns: True if the bank is visible
    func isBankVisible(_ bankName: String) -> Bool {
        return visibleBanks.contains(bankName)
    }
    
    /// Resets bank visibility to show all banks
    func resetBankVisibility() {
        visibleBanks = Set(availableBanks)
    }
    
    // MARK: - Private Methods
    
    /// Save the selected language to UserDefaults
    private func saveSelectedLanguage() {
        UserDefaults.standard.set(selectedLanguage.rawValue, forKey: UserDefaultsKeys.selectedLanguage)
    }
    
    /// Save visible banks to UserDefaults
    private func saveVisibleBanks() {
        UserDefaults.standard.set(Array(visibleBanks), forKey: UserDefaultsKeys.visibleBanks)
        
        // Post notification for views to refresh their data
        NotificationCenter.default.post(name: Notification.Name("BankVisibilityChanged"), object: nil)
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
