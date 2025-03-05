//
//  HistoricalExchangeRatesService.swift
//  CurrEx
//
//  Created for CurrEx on 05.03.2025.
//

import Foundation

// MARK: - Historical API Service
final class HistoricalExchangeRatesService: HistoricalExchangeRatesServiceProtocol {
    private let credentialsString: String
    private let baseURL: String
    private let cache = NSCache<NSString, CachedHistoricalRates>()
    private let cacheExpirationTime: TimeInterval = 1800 // 30 minutes
    
    // Cache class to store rates with timestamp
    final class CachedHistoricalRates {
        let rates: [HistoricalRateDataPoint]
        let timestamp: Date
        
        init(rates: [HistoricalRateDataPoint], timestamp: Date = Date()) {
            self.rates = rates
            self.timestamp = timestamp
        }
        
        var isValid: Bool {
            return Date().timeIntervalSince(timestamp) < 1800 // 30 minutes
        }
    }
    
    /// Creates an instance of the historical exchange rates service
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
    
    /// Fetches historical exchange rates for specified currency and period
    /// - Parameters:
    ///   - currency: Currency code (e.g. "USD", "EUR")
    ///   - period: Number of days to look back
    /// - Returns: Array of historical rate data points
    /// - Throws: NetworkError if request fails or response can't be parsed
    func fetchHistoricalRates(for currency: String, period: Int) async throws -> [HistoricalRateDataPoint] {
        // Check cache first
        let cacheKey = NSString(string: "\(currency)_\(period)")
        if let cachedData = cache.object(forKey: cacheKey), cachedData.isValid {
            return cachedData.rates
        }
        
        // TODO: Use proper base URL from settings, not hardcoded
        // Prepare URL request
        guard let url = URL(string: "\(baseURL)/api/exchange_rates_period?currency=\(currency)&period=\(period)") else {
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
            let response = try JSONDecoder().decode(HistoricalExchangeRateResponse.self, from: data)
            
            // Transform data to view model format
            var results: [HistoricalRateDataPoint] = []
            results.reserveCapacity(response.data.count) // Pre-allocate capacity for performance
            
            // Create formatter once
            let isoFormatter = Formatters.isoFormatter
            
            for dataPoint in response.data {
                guard let date = isoFormatter.date(from: dataPoint.timestamp) else { continue }
                
                var bankRates: [String: (buy: Double, sell: Double)] = [:]
                
                // Process Bestobmin
                if let bestobminRates = dataPoint.rates.Bestobmin, let rate = bestobminRates.first {
                    let buyRate = parseAndRound(rate.rate_buy)
                    let sellRate = parseAndRound(rate.rate_sell)
                    bankRates["Bestobmin"] = (buy: buyRate, sell: sellRate)
                }
                
                // Process PrivatBank
                if let privatBankRates = dataPoint.rates.PrivatBank, let rate = privatBankRates.first {
                    let buyRate = parseAndRound(rate.rate_buy)
                    let sellRate = parseAndRound(rate.rate_sell)
                    bankRates["PrivatBank"] = (buy: buyRate, sell: sellRate)
                }
                
                // Process Raiffeisen
                if let raiffeisenRates = dataPoint.rates.Raiffeisen, let rate = raiffeisenRates.first {
                    let buyRate = parseAndRound(rate.rate_buy)
                    let sellRate = parseAndRound(rate.rate_sell)
                    bankRates["Raiffeisen"] = (buy: buyRate, sell: sellRate)
                }
                
                // Only add data point if we have at least one bank rate
                if !bankRates.isEmpty {
                    results.append(HistoricalRateDataPoint(
                        date: date,
                        bankRates: bankRates
                    ))
                }
            }
            
            // Sort by date
            results.sort { $0.date < $1.date }
            
            // Store in cache
            let cachedData = CachedHistoricalRates(rates: results)
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
