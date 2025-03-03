//
//  LoadingErrorViews.swift
//  CurrEx
//

import SwiftUI

struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Завантаження курсів валют...")
                .font(.headline)
                .foregroundColor(.gray)
                .padding(.top, 16)
        }
    }
}

struct ErrorView: View {
    let message: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.red)
            
            Text("Помилка")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.red)
            
            Text(message)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: retryAction) {
                Text("Спробувати знову")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}

struct LastUpdatedView: View {
    let timestamp: String
    
    var body: some View {
        HStack {
            Spacer()
            Text("Оновлено: \(timestamp)")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

struct DisclaimerView: View {
    var body: some View {
        Text("Дані курсів валют надаються лише в інформаційних цілях та можуть відрізнятися від актуальних значень.")
            .font(.caption)
            .foregroundColor(.gray)
            .multilineTextAlignment(.center)
            .padding(.vertical)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    VStack(spacing: 30) {
        LoadingView()
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            
        ErrorView(message: "Не вдалося завантажити дані. Перевірте підключення до інтернету.") {
            print("Retry tapped")
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
            
        LastUpdatedView(timestamp: "25.02.2025 15:30")
        
        DisclaimerView()
    }
    .padding()
    .background(Color(UIColor.systemGray6))
}
