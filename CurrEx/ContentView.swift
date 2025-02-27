import SwiftUI
import Charts

// MARK: - Моделі даних
struct ExchangeRateResponse: Codable {
    let Bestobmin: [BankRate]
    let PrivatBank: [BankRate]
    let Raiffeisen: [BankRate]
    let timestamp: String
    
    enum CodingKeys: String, CodingKey {
        case Bestobmin
        case PrivatBank
        case Raiffeisen
        case timestamp
    }
}

struct BankRate: Codable {
    let base_currency: String
    let currency: String
    let rate_buy: String
    let rate_sell: String
}

// MARK: - Моделі представлення
struct BankRateViewModel: Identifiable {
    let id = UUID()
    let name: String
    let buyRate: Double
    let sellRate: Double
    
    var spread: Double {
        return sellRate - buyRate
    }
}

// MARK: - API сервіс
class ExchangeRatesService {
    // Замініть credentialsString на ваш логін і пароль у форматі "username:password"
    private let credentialsString = "user:sWgYRGiRV2e70wA"
    
    func fetchExchangeRates(for currency: String) async throws -> [BankRateViewModel] {
        guard let url = URL(string: "https://mvadim.pythonanywhere.com/api/exchange_rates?currency=\(currency)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        
        // Додаємо Basic Auth
        if let data = credentialsString.data(using: .utf8) {
            let base64String = data.base64EncodedString()
            request.addValue("Basic \(base64String)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(ExchangeRateResponse.self, from: data)
        
        // Перетворення даних у формат ViewModel
        var results: [BankRateViewModel] = []
        
        if let rate = response.Bestobmin.first {
            // Використовуємо NumberFormatter для правильного перетворення і округлення
            let buyRate = parseAndRound(rate.rate_buy)
            let sellRate = parseAndRound(rate.rate_sell)
            
            results.append(BankRateViewModel(
                name: "Bestobmin",
                buyRate: buyRate,
                sellRate: sellRate
            ))
        }
        
        if let rate = response.PrivatBank.first {
            let buyRate = parseAndRound(rate.rate_buy)
            let sellRate = parseAndRound(rate.rate_sell)
            
            results.append(BankRateViewModel(
                name: "PrivatBank",
                buyRate: buyRate,
                sellRate: sellRate
            ))
        }
        
        if let rate = response.Raiffeisen.first {
            let buyRate = parseAndRound(rate.rate_buy)
            let sellRate = parseAndRound(rate.rate_sell)
            
            results.append(BankRateViewModel(
                name: "Raiffeisen",
                buyRate: buyRate,
                sellRate: sellRate
            ))
        }
        
        return results
    }
    
    // Допоміжна функція для парсингу та округлення значень
    private func parseAndRound(_ value: String) -> Double {
        guard let doubleValue = Double(value) else { return 0.0 }
        // Округлюємо до 2 десяткових знаків
        return round(doubleValue * 1000) / 1000
    }
}

// MARK: - Головний екран
struct ExchangeRateView: View {
    @State private var rates: [BankRateViewModel] = []
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    @State private var lastUpdated: String = ""
    @State private var selectedCurrency: String = "USD"
    
    private let service = ExchangeRatesService()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGray6).edgesIgnoringSafeArea(.all)
                
                if isLoading {
                    loadingView
                } else if let error = errorMessage {
                    errorView(message: error)
                } else {
                    mainContentView
                }
            }
            .navigationTitle("Курс валют в Україні")
        }
        .onAppear {
            loadData()
        }
    }
    
    // MARK: - Завантаження даних
    private func loadData() {
        isLoading = true
        errorMessage = nil
        
        Task {
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
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "uk_UA")
        return formatter.string(from: Date())
    }
    
    // MARK: - Допоміжні функції
    private func findBestRates() -> (buy: BankRateViewModel?, sell: BankRateViewModel?) {
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
    
    // MARK: - Підвиди інтерфейсу
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
            
            Button(action: loadData) {
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
            VStack(spacing: 16) {
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
            
            Picker("Валюта", selection: $selectedCurrency) {
                Text("USD").tag("USD")
                Text("EUR").tag("EUR")
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: selectedCurrency) { _ in
                loadData()
            }
        }
        .padding(.vertical, 8)
    }
    
    private var lastUpdatedView: some View {
        HStack {
            Spacer()
            Text("Оновлено: \(lastUpdated)")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
    
    private var bestRatesView: some View {
        let bestRates = findBestRates()
        
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
    
    // Якщо ви використовуєте iOS 16+, також покращимо нативні Charts
    private var chartView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Порівняння курсів")
                .font(.headline)
                .fontWeight(.semibold)
            
            // На iOS 16+ використовуємо нативні Charts
            if #available(iOS 16.0, *) {
                Chart {
                    ForEach(rates) { rate in
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
                    // Відступ знизу для уникнення перекриття підписів
                    plotArea
                        .padding(.bottom, 30)
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let label = value.as(String.self) {
                                Text(label)
                                    .rotationEffect(.degrees(-90))  // Обертання на -90градусів
                                    .offset(x: 0, y: 8)              // Зсув підпису
                            }
                        }
                        AxisTick()
                        AxisGridLine()
                    }
                }
                .frame(height: 250)
                .chartYScale(domain: getChartYDomain())
                .chartLegend(position: .top, alignment: .center)
                
            }
                else {
                // Для iOS 15 альтернативні графіки
                alternativeChartView
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    // Покращена функція для визначення меж графіка
    private func getChartYDomain() -> ClosedRange<Double> {
        guard !rates.isEmpty else { return 0...50 }
        
        let minValue = (rates.map { $0.buyRate }.min() ?? 0) * 0.99 // Додаємо невеликий запас знизу (2%)
        let maxValue = (rates.map { $0.sellRate }.max() ?? 50) * 1.01 // Додаємо невеликий запас зверху (2%)
        
        return minValue...maxValue
    }

    
    // Альтернативне відображення графіка для iOS 15 та нижче
    private var alternativeChartView: some View {
        VStack(spacing: 16) {
            Text("Курси в графічному вигляді доступні в iOS 16+")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            // Візуалізація через стовпчики
            HStack(alignment: .bottom, spacing: 12) {
                ForEach(rates) { rate in
                    VStack(spacing: 4) {
                        // Стовпчик продажу
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
                        
                        // Стовпчик купівлі
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
                        
                        // Назва банку
                        Text(rate.name)
                            .font(.caption)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.center)
                            .frame(width: 70)
                    }
                }
            }
            .frame(height: 250)
            
            // Легенда
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
                // Заголовок таблиці
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
                
                // Рядки таблиці
                ForEach(rates) { rate in
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

