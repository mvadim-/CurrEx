//
//  SettingsView.swift
//  CurrEx
//
//  Created for CurrEx on 05.03.2025.
//

import SwiftUI

/// View for displaying and changing app settings
struct SettingsView: View {
    // MARK: - Properties
    
    /// Settings manager for the app
    @ObservedObject private var settingsManager = SettingsManager.shared
    
    /// Environment presentation mode for dismissing the view
    @Environment(\.presentationMode) var presentationMode
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            List {
                // MARK: - Language Section
                Section(header: Text(NSLocalizedString("Language", comment: "Language settings section title"))) {
                    ForEach(Language.allCases) { language in
                        Button(action: {
                            settingsManager.selectedLanguage = language
                        }) {
                            HStack {
                                Text(language.flagEmoji)
                                    .font(.title2)
                                    .padding(.trailing, 8)
                                
                                Text(language.displayName)
                                    .foregroundColor(AppColors.text)
                                
                                Spacer()
                                
                                if settingsManager.selectedLanguage == language {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(AppColors.accentColor)
                                }
                            }
                        }
                        .contentShape(Rectangle())
                    }
                }
                
                // MARK: - Info Section
                Section(header: Text(NSLocalizedString("Information", comment: "Information section title"))) {
                    HStack {
                        Text(NSLocalizedString("Version", comment: "App version label"))
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                            .foregroundColor(AppColors.secondaryText)
                    }
                    
                    HStack {
                        Text(NSLocalizedString("Build", comment: "App build label"))
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                            .foregroundColor(AppColors.secondaryText)
                    }
                }
                
                // MARK: - Notice about app restart
                Section {
                    Text(NSLocalizedString("Some settings may require restarting the app to fully take effect.", comment: "Settings restart notice"))
                        .font(.caption)
                        .foregroundColor(AppColors.secondaryText)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(Color.clear)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle(NSLocalizedString("Settings", comment: "Settings view title"))
            .navigationBarItems(trailing: Button(NSLocalizedString("Done", comment: "Close settings button")) {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}
