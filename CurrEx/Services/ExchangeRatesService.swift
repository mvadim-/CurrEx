//
//  ExchangeRatesService.swift
//  CurrEx
//
//  Created for CurrEx on 05.03.2025.
//

import Foundation

// MARK: - API Service
final class ExchangeRatesService: ExchangeRatesServiceProtocol {
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
    
    /// Creates an instance of the exchange rates service
    /// - Throws: NetworkError.invalidConfiguration if required settings are missing
    init() {
        guard let infoDict = Bundle.main.infoDictionary,
              let credentials = infoDict["CredentialsString"] as? String,
              let url = infoDict["BaseURL"] as? String else {
            // Using a dummy credential for development - should be replaced with proper error handling
            self.credentialsString = "dummy-credential"
            self.baseURL = "https://api.example.com"
            print("Warning: Missing API configuration in Info.plist")
            return
        }
        
        self.credentialsString = credentials
        self.baseURL = url.replacingOccurrences(of: "___", with: "://")
    }
    
    /// Fetches current exchange rates for specified currency
    /// - Parameter currency: Currency code (e.g. "USD", "EUR")
    /// - Returns: Array of bank rates for the requested currency
    /// - Throws: NetworkError if request fails or response can't be parsed
    func fetchExchangeRates(for currency: String) async throws -> [BankRateViewModel] {
        // Check cache first
        let cacheKey = NSString(string: currency)
        if let cachedData = cache.object(forKey: cacheKey), cachedData.isValid {
            return cachedData.rates
        }
        
        // Prepare URL request
        guard let url = URL(string: "\(baseURL)/api/exchange_rates?currency=\(currency)") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        // Add Basic Auth
        if let data = credentialsString.data(using: .utf8) {
            let base64String = data.base64EncodedString()
            request.addValue("Basic \(base64String)", forHTTPHeaderField: "Authorization")
        }
        
        // Make network request using async/await
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Validate response
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }
        
        // Parse response
        do {
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
        } catch {
            throw NetworkError.decodingFailed(error)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Parses a string value to Double and rounds it to 3 decimal places
    /// - Parameter value: String representation of a number
    /// - Returns: Rounded Double value
    private func parseAndRound(_ value: String) -> Double {
        guard let doubleValue = Double(value) else { return 0.0 }
        return (doubleValue * 1000).rounded() / 1000
    }
}
