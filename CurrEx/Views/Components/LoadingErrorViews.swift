//
//  LoadingErrorViews.swift
//  CurrEx
//
//  Created for CurrEx on 05.03.2025.
//

import SwiftUI

/// Loading state view
struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
            
            Text(NSLocalizedString("Loading exchange rates...", comment: "Loading state message"))
                .font(.headline)
                .foregroundColor(AppColors.secondaryText)
                .padding(.top, 16)
        }
        .padding()
        .background(AppColors.background)
        .cornerRadius(12)
    }
}

/// Error state view with retry action
struct ErrorView: View {
    let message: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.red)
            
            Text(NSLocalizedString("Error", comment: "Error title"))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.red)
            
            Text(message)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .foregroundColor(AppColors.text)
            
            Button(action: retryAction) {
                Text(NSLocalizedString("Try Again", comment: "Retry button"))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(AppColors.accentColor)
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(AppColors.background)
        .cornerRadius(12)
    }
}

/// Last updated timestamp view
struct LastUpdatedView: View {
    let timestamp: String
    
    var body: some View {
        HStack {
            Spacer()
            Text("\(NSLocalizedString("Updated:", comment: "Last updated label")) \(timestamp)")
                .font(.caption)
                .foregroundColor(AppColors.secondaryText)
        }
    }
}

/// Disclaimer text view
struct DisclaimerView: View {
    var body: some View {
        Text(NSLocalizedString("Exchange rate data is provided for informational purposes only and may differ from actual values.", comment: "Disclaimer text"))
            .font(.caption)
            .foregroundColor(AppColors.secondaryText)
            .multilineTextAlignment(.center)
            .padding(.vertical)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    VStack(spacing: 30) {
        LoadingView()
            
        ErrorView(message: "Failed to load data. Please check your internet connection.") {
            print("Retry tapped")
        }
            
        LastUpdatedView(timestamp: "25.02.2025 15:30")
        
        DisclaimerView()
    }
    .padding()
    .background(AppColors.groupedBackground)
}
