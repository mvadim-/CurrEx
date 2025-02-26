import SwiftUI
import Foundation
import Combine

// MARK: - Моделі даних
struct ExchangeRate: Codable, Identifiable {
    var id = UUID()
    let baseCurrency: String
    let currency: String
    let rateBuy: String
    let rateSell: String
    
    enum CodingKeys: String, CodingKey {
        case baseCurrency = "base_currency"
        case currency
        case rateBuy = "rate_buy"
        case rateSell = "rate_sell"
    }
}

struct ExchangeRatesResponse: Codable {
    let bestobmin: [ExchangeRate]
    let privatBank: [ExchangeRate]
    let raiffeisen: [ExchangeRate]
    let timestamp: String
    
    enum CodingKeys: String, CodingKey {
        case bestobmin = "Bestobmin"
        case privatBank = "PrivatBank"
        case raiffeisen = "Raiffeisen"
        case timestamp
    }
}

struct BankRate: Identifiable {
    var id = UUID()
    let bank: String
    let buyRate: Double
    let sellRate: Double
    var buyColor: Color {
        isBestBuy ? .green : .primary
    }
    var sellColor: Color {
        isBestSell ? .green : .primary
    }
    var isBestBuy: Bool = false
    var isBestSell: Bool = false
}

// MARK: - ViewModel
class ExchangeRatesViewModel: ObservableObject {
    @Published var bankRates: [BankRate] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastUpdated: String = ""
    
    func fetchExchangeRates(currency: String) {
        isLoading = true
        errorMessage = nil
        
        guard let url = URL(string: "https://mvadim.pythonanywhere.com/api/exchange_rates?currency=\(currency)") else {
            errorMessage = "Невірний URL"
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        
        // Додаємо Basic Auth
        // Замініть "username:password" на ваші дані для авторизації
        let authString = "username:password"
        if let authData = authString.data(using: .utf8) {
            let base64Auth = authData.base64EncodedString()
            request.addValue("Basic \(base64Auth)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Помилка: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    self?.errorMessage = "Немає даних"
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    let response = try decoder.decode(ExchangeRatesResponse.self, from: data)
                    
                    // Форматування часу
                    if let date = ISO8601DateFormatter().date(from: response.timestamp) {
                        let formatter = DateFormatter()
                        formatter.dateStyle = .medium
                        formatter.timeStyle = .short
                        formatter.locale = Locale(identifier: "uk_UA")
                        self?.lastUpdated = formatter.string(from: date)
                    } else {
                        self?.lastUpdated = response.timestamp
                    }
                    
                    // Підготовка даних для відображення
                    var rates = [
                        BankRate(
                            bank: "Bestobmin",
                            buyRate: Double(response.bestobmin[0].rateBuy) ?? 0,
                            sellRate: Double(response.bestobmin[0].rateSell) ?? 0
                        ),
                        BankRate(
                            bank: "ПриватБанк",
                            buyRate: Double(response.privatBank[0].rateBuy) ?? 0,
                            sellRate: Double(response.privatBank[0].rateSell) ?? 0
                        ),
                        BankRate(
                            bank: "Райффайзен",
                            buyRate: Double(response.raiffeisen[0].rateBuy) ?? 0,
                            sellRate: Double(response.raiffeisen[0].rateSell) ?? 0
                        )
                    ]
                    
                    // Визначення найкращих курсів
                    if let bestBuyRate = rates.min(by: { $0.buyRate < $1.buyRate }) {
                        for i in 0..<rates.count {
                            if rates[i].buyRate == bestBuyRate.buyRate {
                                rates[i].isBestBuy = true
                            }
                        }
                    }
                    
                    if let bestSellRate = rates.max(by: { $0.sellRate < $1.sellRate }) {
                        for i in 0..<rates.count {
                            if rates[i].sellRate == bestSellRate.sellRate {
                                rates[i].isBestSell = true
                            }
                        }
                    }
                    
                    self?.bankRates = rates
                } catch {
                    self?.errorMessage = "Помилка розбору даних: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
}

// MARK: - Views
struct ExchangeRatesView: View {
    @StateObject private var viewModel = ExchangeRatesViewModel()
    @State private var selectedCurrency = "USD"
    
    var body: some View {
        NavigationView {
            VStack {
                // Секція селектора валюти (заготовка для майбутнього розширення)
                Picker("Валюта", selection: $selectedCurrency) {
                    Text("USD").tag("USD")
                    Text("EUR").tag("EUR")
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .onChange(of: selectedCurrency) { oldValue, newValue in
                    viewModel.fetchExchangeRates(currency: selectedCurrency)
                }
                
                if viewModel.isLoading {
                    ProgressView("Завантаження...")
                        .padding()
                } else if let errorMessage = viewModel.errorMessage {
                    ErrorView(errorMessage: errorMessage, retryAction: {
                        viewModel.fetchExchangeRates(currency: selectedCurrency)
                    })
                } else if viewModel.bankRates.isEmpty {
                    Text("Немає даних")
                        .padding()
                } else {
                    // Головна секція з курсами валют
                    RatesView(bankRates: viewModel.bankRates)
                    
                    // Графічне порівняння
                    ComparisonChartView(bankRates: viewModel.bankRates)
                    
                    Spacer()
                    
                    // Інформація про останнє оновлення
                    if !viewModel.lastUpdated.isEmpty {
                        Text("Останнє оновлення: \(viewModel.lastUpdated)")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 8)
                    }
                }
            }
            .navigationTitle("Курс валют")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.fetchExchangeRates(currency: selectedCurrency)
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .onAppear {
                viewModel.fetchExchangeRates(currency: selectedCurrency)
            }
        }
    }
}

struct RatesView: View {
    let bankRates: [BankRate]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("USD / UAH")
                .font(.headline)
                .padding(.horizontal)
            
            // Заголовок таблиці
            HStack {
                Text("Банк")
                    .fontWeight(.bold)
                    .frame(width: 120, alignment: .leading)
                
                Spacer()
                
                Text("Купівля")
                    .fontWeight(.bold)
                    .frame(width: 80, alignment: .trailing)
                
                Spacer()
                
                Text("Продаж")
                    .fontWeight(.bold)
                    .frame(width: 80, alignment: .trailing)
            }
            .padding(.horizontal)
            .padding(.bottom, 5)
            
            // Список курсів
            ScrollView {
                VStack(spacing: 15) {
                    ForEach(bankRates) { rate in
                        BankRateRow(rate: rate)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct BankRateRow: View {
    let rate: BankRate
    
    var body: some View {
        HStack {
            Text(rate.bank)
                .frame(width: 120, alignment: .leading)
            
            Spacer()
            
            Text(String(format: "%.2f", rate.buyRate))
                .fontWeight(rate.isBestBuy ? .bold : .regular)
                .foregroundColor(rate.buyColor)
                .frame(width: 80, alignment: .trailing)
            
            Spacer()
            
            Text(String(format: "%.2f", rate.sellRate))
                .fontWeight(rate.isBestSell ? .bold : .regular)
                .foregroundColor(rate.sellColor)
                .frame(width: 80, alignment: .trailing)
        }
        .padding(10)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(8)
    }
}

struct ComparisonChartView: View {
    let bankRates: [BankRate]
    
    // Знайти мінімальні та максимальні значення для масштабування графіка
    private var minRate: Double {
        let minBuy = bankRates.map { $0.buyRate }.min() ?? 0
        let minSell = bankRates.map { $0.sellRate }.min() ?? 0
        return min(minBuy, minSell) * 0.99 // Додаємо небольшой отступ
    }
    
    private var maxRate: Double {
        let maxBuy = bankRates.map { $0.buyRate }.max() ?? 0
        let maxSell = bankRates.map { $0.sellRate }.max() ?? 0
        return max(maxBuy, maxSell) * 1.01 // Додаємо небольшой отступ
    }
    
    private var range: Double {
        return maxRate - minRate
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Порівняння курсів")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top)
            
            // Висота графіка
            let height: CGFloat = 150
            
            ZStack(alignment: .bottom) {
                // Вертикальні лінії сітки
                HStack(spacing: 0) {
                    ForEach(0..<5) { i in
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 1, height: height)
                            .padding(.horizontal)
                    }
                }
                
                // Горизонтальні лінії сітки
                VStack(spacing: 0) {
                    ForEach(0..<4) { i in
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: UIScreen.main.bounds.width - 40, height: 1)
                            .padding(.vertical, height / 3)
                    }
                }
                
                // Графік
                VStack(spacing: 20) {
                    // Курс купівлі
                    HStack(alignment: .bottom, spacing: 30) {
                        ForEach(bankRates) { rate in
                            VStack {
                                let barHeight = calculateBarHeight(rate: rate.buyRate, height: height)
                                Rectangle()
                                    .fill(rate.isBestBuy ? Color.green : Color.blue)
                                    .frame(width: 30, height: barHeight)
                                    .cornerRadius(5)
                                
                                Text(rate.bank)
                                    .font(.caption)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(width: 80)
                                    .multilineTextAlignment(.center)
                            }
                        }
                    }
                    
                    // Курс продажу
                    HStack(alignment: .bottom, spacing: 30) {
                        ForEach(bankRates) { rate in
                            VStack {
                                let barHeight = calculateBarHeight(rate: rate.sellRate, height: height)
                                Rectangle()
                                    .fill(rate.isBestSell ? Color.green : Color.orange)
                                    .frame(width: 30, height: barHeight)
                                    .cornerRadius(5)
                                
                                Text(rate.bank)
                                    .font(.caption)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(width: 80)
                                    .multilineTextAlignment(.center)
                            }
                        }
                    }
                }
            }
            
            // Легенда
            HStack {
                HStack {
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: 15, height: 15)
                    
                    Text("Купівля")
                        .font(.caption)
                }
                
                Spacer()
                
                HStack {
                    Rectangle()
                        .fill(Color.orange)
                        .frame(width: 15, height: 15)
                    
                    Text("Продаж")
                        .font(.caption)
                }
                
                Spacer()
                
                HStack {
                    Rectangle()
                        .fill(Color.green)
                        .frame(width: 15, height: 15)
                    
                    Text("Найкращий курс")
                        .font(.caption)
                }
            }
            .padding()
        }
        .padding(.bottom)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .padding()
    }
    
    private func calculateBarHeight(rate: Double, height: CGFloat) -> CGFloat {
        if range == 0 { return height * 0.5 }
        let normalized = (rate - minRate) / range
        return CGFloat(normalized) * height * 0.8 + height * 0.2
    }
}

struct ErrorView: View {
    let errorMessage: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.red)
            
            Text("Помилка")
                .font(.headline)
            
            Text(errorMessage)
                .multilineTextAlignment(.center)
                .padding()
            
            Button(action: retryAction) {
                Text("Спробувати знову")
                    .fontWeight(.bold)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
    }
}

// MARK: - Точка входу
@main
struct ExchangeRatesApp: App {
    var body: some Scene {
        WindowGroup {
            ExchangeRatesView()
        }
    }
}
