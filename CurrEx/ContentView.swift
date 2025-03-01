import SwiftUI
import Charts

// MARK: - Data Models
struct ExchangeRateResponse: Codable {
    let Bestobmin: [BankRate]
    let PrivatBank: [BankRate]
    let Raiffeisen: [BankRate]
    let timestamp: String
}

struct BankRate: Codable {
    let base_currency: String
    let currency: String
    let rate_buy: String
    let rate_sell: String
}

// MARK: - View Models
struct BankRateViewModel: Identifiable {
    let id = UUID()
    let name: String
    let buyRate: Double
    let sellRate: Double
    
    var spread: Double {
        return sellRate - buyRate
    }
}

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
                    sellRate: sellRate
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

// MARK: - Main Content View Model
class ExchangeRateViewModel: ObservableObject {
    @Published var rates: [BankRateViewModel] = []
    @Published var isLoading = true
    @Published var errorMessage: String? = nil
    @Published var lastUpdated: String = ""
    @Published var selectedCurrency: String = "USD"
    
    private let service = ExchangeRatesService()
    private let dateFormatter: DateFormatter
    
    init() {
        // Initialize date formatter once
        dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        dateFormatter.locale = Locale(identifier: "uk_UA")
    }
    
    func loadData() {
        isLoading = true
        errorMessage = nil
        
        Task { @MainActor in
            do {
                rates = try await service.fetchExchangeRates(for: selectedCurrency)
                lastUpdated = formatCurrentTime()
                isLoading = false
            } catch {
                errorMessage = "Помилка завантаження даних: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    private func formatCurrentTime() -> String {
        return dateFormatter.string(from: Date())
    }
    
    func findBestRates() -> (buy: BankRateViewModel?, sell: BankRateViewModel?) {
        guard let firstRate = rates.first else { return (nil, nil) }
        
        var bestBuy = firstRate
        var bestSell = firstRate
        
        for rate in rates {
            if rate.buyRate > bestBuy.buyRate {
                bestBuy = rate
            }
            if rate.sellRate < bestSell.sellRate {
                bestSell = rate
            }
        }
        
        return (bestBuy, bestSell)
    }
    
    func getChartYDomain() -> ClosedRange<Double> {
        guard !rates.isEmpty else { return 0...50 }
        
        let minValue = (rates.map { $0.buyRate }.min() ?? 0) * 0.99
        let maxValue = (rates.map { $0.sellRate }.max() ?? 50) * 1.01
        
        return minValue...maxValue
    }
}

// MARK: - Main View
struct ExchangeRateView: View {
    @StateObject private var viewModel = ExchangeRateViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGray6).edgesIgnoringSafeArea(.all)
                
                if viewModel.isLoading {
                    loadingView
                } else if let error = viewModel.errorMessage {
                    errorView(message: error)
                } else {
                    mainContentView
                }
            }
            .navigationTitle("Курс валют в Україні")
        }
        .onAppear {
            viewModel.loadData()
        }
    }
    
    // MARK: - Subviews
    private var loadingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Завантаження курсів валют...")
                .font(.headline)
                .foregroundColor(.gray)
                .padding(.top, 16)
        }
    }
    
    private func errorView(message: String) -> some View {
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
            
            Button(action: viewModel.loadData) {
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
    
    private var mainContentView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                currencySelector
                
                lastUpdatedView
                
                bestRatesView
                
                chartView
                
                detailedInfoView
                
                disclaimerView
            }
            .padding()
        }
    }
    
    private var currencySelector: some View {
        HStack {
            Text("Валюта:")
                .font(.headline)
            
            Picker("Валюта", selection: $viewModel.selectedCurrency) {
                Text("USD").tag("USD")
                Text("EUR").tag("EUR")
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: viewModel.selectedCurrency) { oldValue, newValue in
                viewModel.loadData()
            }
        }
        .padding(.vertical, 8)
    }
    
    private var lastUpdatedView: some View {
        HStack {
            Spacer()
            Text("Оновлено: \(viewModel.lastUpdated)")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
    
    private var bestRatesView: some View {
        let bestRates = viewModel.findBestRates()
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("Найкращі курси")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Найвигідніше продати у")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    if let bestBuy = bestRates.buy {
                        Text("\(bestBuy.name): \(String(format: "%.2f", bestBuy.buyRate)) ₴")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.green.opacity(0.1))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Найвигідніше купити у")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    if let bestSell = bestRates.sell {
                        Text("\(bestSell.name): \(String(format: "%.2f", bestSell.sellRate)) ₴")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var chartView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Порівняння курсів")
                .font(.headline)
                .fontWeight(.semibold)
            
            if #available(iOS 16.0, *) {
                Chart {
                    ForEach(viewModel.rates) { rate in
                        BarMark(
                            x: .value("Банк", rate.name),
                            y: .value("Курс", rate.buyRate)
                        )
                        .foregroundStyle(Color.green)
                        .position(by: .value("Тип", "Купівля"), axis: .horizontal)
                        .annotation(position: .top) {
                            Text(String(format: "%.2f", rate.buyRate))
                                .font(.caption2)
                                .foregroundColor(.black)
                        }

                        BarMark(
                            x: .value("Банк", rate.name),
                            y: .value("Курс", rate.sellRate)
                        )
                        .foregroundStyle(Color.blue)
                        .position(by: .value("Тип", "Продаж"), axis: .horizontal)
                        .annotation(position: .top) {
                            Text(String(format: "%.2f", rate.sellRate))
                                .font(.caption2)
                                .foregroundColor(.black)
                        }
                    }
                }
                .chartPlotStyle { plotArea in
                    plotArea.padding(.bottom, 30)
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let label = value.as(String.self) {
                                Text(label)
                                    .rotationEffect(.degrees(-90))
                                    .offset(x: 0, y: 8)
                            }
                        }
                        AxisTick()
                        AxisGridLine()
                    }
                }
                .frame(height: 250)
                .chartYScale(domain: viewModel.getChartYDomain())
                .chartLegend(position: .top, alignment: .center)
            } else {
                alternativeChartView
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var alternativeChartView: some View {
        VStack(spacing: 16) {
            Text("Курси в графічному вигляді доступні в iOS 16+")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            HStack(alignment: .bottom, spacing: 12) {
                ForEach(viewModel.rates) { rate in
                    VStack(spacing: 4) {
                        VStack {
                            Spacer()
                            Text(String(format: "%.2f", rate.sellRate))
                                .font(.caption2)
                                .foregroundColor(.white)
                                .rotationEffect(.degrees(-90))
                                .padding(.vertical, 2)
                        }
                        .frame(width: 30, height: CGFloat(rate.sellRate * 5))
                        .background(Color.blue)
                        .cornerRadius(4)
                        
                        VStack {
                            Spacer()
                            Text(String(format: "%.2f", rate.buyRate))
                                .font(.caption2)
                                .foregroundColor(.white)
                                .rotationEffect(.degrees(-90))
                                .padding(.vertical, 2)
                        }
                        .frame(width: 30, height: CGFloat(rate.buyRate * 5))
                        .background(Color.green)
                        .cornerRadius(4)
                        
                        Text(rate.name)
                            .font(.caption)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.center)
                            .frame(width: 70)
                    }
                }
            }
            .frame(height: 250)
            
            HStack(spacing: 16) {
                HStack(spacing: 8) {
                    Rectangle()
                        .fill(Color.green)
                        .frame(width: 12, height: 12)
                    Text("Купівля")
                        .font(.caption)
                }
                
                HStack(spacing: 8) {
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: 12, height: 12)
                    Text("Продаж")
                        .font(.caption)
                }
            }
        }
    }
    
    private var detailedInfoView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Детальна інформація")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 0) {
                HStack {
                    Text("Банк")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("Купівля")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(width: 70, alignment: .trailing)
                    
                    Text("Продаж")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(width: 70, alignment: .trailing)
                    
                    Text("Спред")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(width: 70, alignment: .trailing)
                }
                .padding(.vertical, 10)
                .padding(.horizontal)
                .background(Color(UIColor.systemGray5))
                
                ForEach(viewModel.rates) { rate in
                    HStack {
                        Text(rate.name)
                            .font(.subheadline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text(String(format: "%.2f", rate.buyRate))
                            .font(.subheadline)
                            .frame(width: 70, alignment: .trailing)
                        
                        Text(String(format: "%.2f", rate.sellRate))
                            .font(.subheadline)
                            .frame(width: 70, alignment: .trailing)
                        
                        Text(String(format: "%.2f", rate.spread))
                            .font(.subheadline)
                            .frame(width: 70, alignment: .trailing)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal)
                    .background(Color.white)
                    .overlay(
                        Divider()
                            .background(Color(UIColor.systemGray4))
                            .offset(y: 20),
                        alignment: .bottom
                    )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(UIColor.systemGray4), lineWidth: 1)
            )
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var disclaimerView: some View {
        Text("Дані курсів валют надаються лише в інформаційних цілях та можуть відрізнятися від актуальних значень.")
            .font(.caption)
            .foregroundColor(.gray)
            .multilineTextAlignment(.center)
            .padding(.vertical)
    }
}



