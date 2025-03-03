//
//  ExchangeRatesService.swift
//  CurrEx
//

import Foundation

// MARK: - API Service
class ExchangeRatesService {
    private let credentialsString: String
    private let baseURL: String
    private let cache = NSCache<NSString, CachedRates>()
    private let cacheExpirationTime: TimeInterval = 300 // 5 minutes
    
    // Cache class to store rates with timestamp
    final class CachedRates {
        let rates: [BankRateViewModel]
        let timestamp: Date
        
        init(rates: [BankRateViewModel], timestamp: Date = Date()) {
            self.rates = rates
            self.timestamp = timestamp
        }
        
        var isValid: Bool {
            return Date().timeIntervalSince(timestamp) < 300 // 5 minutes
        }
    }
    
    init() {
        guard let infoDict = Bundle.main.infoDictionary,
              let credentials = infoDict["CredentialsString"] as? String,
              let url = infoDict["BaseURL"] as? String else {
            fatalError("Missing configuration in Info.plist")
        }
        
        self.credentialsString = credentials
        self.baseURL = url.replacingOccurrences(of: "___", with: "://")
    }
    
    func fetchExchangeRates(for currency: String) async throws -> [BankRateViewModel] {
        // Check cache first
        let cacheKey = NSString(string: currency)
        if let cachedData = cache.object(forKey: cacheKey), cachedData.isValid {
            return cachedData.rates
        }
        
        // Prepare URL request
        guard let url = URL(string: "\(baseURL)?currency=\(currency)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        // Add Basic Auth
        if let data = credentialsString.data(using: .utf8) {
            let base64String = data.base64EncodedString()
            request.addValue("Basic \(base64String)", forHTTPHeaderField: "Authorization")
        }
        
        // Make network request using async/await
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(ExchangeRateResponse.self, from: data)
        
        // Transform data to view model format more efficiently
        var results: [BankRateViewModel] = []
        results.reserveCapacity(3) // Pre-allocate capacity for performance
        
        // Process each bank data
        let banks = [
            ("Bestobmin", response.Bestobmin.first),
            ("PrivatBank", response.PrivatBank.first),
            ("Raiffeisen", response.Raiffeisen.first)
        ]
        
        for (name, rateData) in banks {
            if let rate = rateData {
                let buyRate = parseAndRound(rate.rate_buy)
                let sellRate = parseAndRound(rate.rate_sell)
                
                results.append(BankRateViewModel(
                    name: name,
                    buyRate: buyRate,
                    sellRate: sellRate,
                    timestamp: response.timestamp
                ))
            }
        }
        
        // Store in cache
        let cachedData = CachedRates(rates: results)
        cache.setObject(cachedData, forKey: cacheKey)
        
        return results
    }
    
    // Helper function for parsing and rounding values
    private func parseAndRound(_ value: String) -> Double {
        guard let doubleValue = Double(value) else { return 0.0 }
        return round(doubleValue * 1000) / 1000
    }
}
