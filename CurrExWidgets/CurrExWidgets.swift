import WidgetKit
import SwiftUI
import Intents

// MARK: - Provider

struct Provider: TimelineProvider {
    
    typealias Entry = RateEntry
    
    func placeholder(in context: Context) -> RateEntry {
        RateEntry(date: Date(), widgetData: .empty)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (RateEntry) -> ()) {
        let entry = RateEntry(date: Date(), widgetData: WidgetDataManager.loadWidgetData())
        completion(entry)
    }
    
    // Переконайтеся, що ви правильно обробляєте помилки
    func getTimeline(in context: Context, completion: @escaping (Timeline<RateEntry>) -> ()) {
        // Оскільки немає операцій, які викидають помилки, можна просто прибрати do-catch
        let widgetData = WidgetDataManager.loadWidgetData()
        let entry = RateEntry(date: Date(), widgetData: widgetData)
        
        // Використовуємо явне порівняння або умову замість ==
        let entries: [RateEntry] = widgetData.bestBuyRates.isEmpty ? [RateEntry(date: Date(), widgetData: .empty)] : [entry]
        
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline<RateEntry>(entries: entries, policy: .after(refreshDate))
        completion(timeline)
    }
}

// MARK: - Entry

struct RateEntry: TimelineEntry {
    let date: Date
    let widgetData: WidgetExchangeRateData
}

// MARK: - Small Widget View

struct SmallRateWidgetView: View {
    var entry: Provider.Entry
    let currencyType: String = "USD" // За замовчуванням USD
    
    var body: some View {
        if #available(iOS 17.0, *) {
            // Використовуємо контейнер без явного фону, оскільки фон вже
            // встановлений у батьківському представленні
            contentView
        } else {
            // Для старих версій iOS використовуємо стандартний підхід
            ZStack {
                Color.clear // або фоновий колір, якщо потрібно
                contentView
            }
        }
    }
    
    private var contentView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(currencyType)
                    .font(.headline)
                    .foregroundColor(Color.blue) // Замінено на системний колір
                
                Spacer()
                
                Text("₴")
                    .font(.headline)
                    .foregroundColor(Color.blue) // Замінено на системний колір
            }
            
            Spacer()
            
            if let bestBuy = entry.widgetData.bestBuyRates[currencyType] {
                HStack(alignment: .center) {
                    Image(systemName: "arrow.up.forward")
                        .foregroundColor(Color.green) // Замінено на системний колір
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Купівля")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text(String(format: "%.2f", bestBuy.buyRate))
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(Color.green) // Замінено на системний колір
                    }
                    
                    Spacer()
                }
            }
            
            if let bestSell = entry.widgetData.bestSellRates[currencyType] {
                HStack(alignment: .center) {
                    Image(systemName: "arrow.down.forward")
                        .foregroundColor(Color.blue) // Замінено на системний колір
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Продаж")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text(String(format: "%.2f", bestSell.sellRate))
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(Color.blue) // Замінено на системний колір
                    }
                    
                    Spacer()
                }
            }
        }
        .padding()
    }
}

// MARK: - Medium Widget View

struct MediumRateWidgetView: View {
    var entry: Provider.Entry
    
    var body: some View {
        if #available(iOS 17.0, *) {
            // Використовуємо контейнер без явного фону для iOS 17+
            contentView
        } else {
            // Для старих версій iOS використовуємо стандартний підхід
            ZStack {
                Color.clear // або фоновий колір, якщо потрібно
                contentView
            }
        }
    }
    
    private var contentView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Курси валют")
                    .font(.headline)
                    .foregroundColor(Color.blue)
                
                Spacer()
                
                Text(entry.date, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                // USD курси
                VStack(alignment: .leading, spacing: 4) {
                    Text("USD")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(Color.blue)
                    
                    if let bestBuyUSD = entry.widgetData.bestBuyRates["USD"],
                       let bestSellUSD = entry.widgetData.bestSellRates["USD"] {
                        
                        HStack {
                            Text("⬆️ " + String(format: "%.2f", bestBuyUSD.buyRate))
                                .foregroundColor(Color.green)
                            
                            Text(bestBuyUSD.bankName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("⬇️ " + String(format: "%.2f", bestSellUSD.sellRate))
                                .foregroundColor(Color.blue)
                            
                            Text(bestSellUSD.bankName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Divider()
                
                // EUR курси
                VStack(alignment: .leading, spacing: 4) {
                    Text("EUR")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(Color.blue)
                    
                    if let bestBuyEUR = entry.widgetData.bestBuyRates["EUR"],
                       let bestSellEUR = entry.widgetData.bestSellRates["EUR"] {
                        
                        HStack {
                            Text("⬆️ " + String(format: "%.2f", bestBuyEUR.buyRate))
                                .foregroundColor(Color.green)
                            
                            Text(bestBuyEUR.bankName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("⬇️ " + String(format: "%.2f", bestSellEUR.sellRate))
                                .foregroundColor(Color.blue)
                            
                            Text(bestSellEUR.bankName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
    }
}

// MARK: - Large Widget View

struct LargeRateWidgetView: View {
    var entry: Provider.Entry
    
    var body: some View {
        if #available(iOS 17.0, *) {
            // Використовуємо контейнер без явного фону для iOS 17+
            contentView
        } else {
            // Для старих версій iOS використовуємо стандартний підхід
            ZStack {
                Color.clear // або фоновий колір, якщо потрібно
                contentView
            }
        }
    }
    
    private var contentView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Курси валют в ІФ")
                    .font(.headline)
                    .foregroundColor(Color.blue)
                
                Spacer()
                
                Text(entry.date, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text("Найкращі курси для обміну")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Divider()
            
            // USD курси
            HStack {
                Text("USD")
                    .font(.headline)
                    .foregroundColor(Color.blue)
                    .frame(width: 60, alignment: .leading)
                
                Spacer()
                
                if let bestBuyUSD = entry.widgetData.bestBuyRates["USD"],
                   let bestSellUSD = entry.widgetData.bestSellRates["USD"] {
                    
                    VStack(alignment: .leading) {
                        Text("Найкраще продати")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text(String(format: "%.2f ₴", bestBuyUSD.buyRate))
                                .fontWeight(.bold)
                                .foregroundColor(Color.green)
                            
                            Text(bestBuyUSD.bankName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading) {
                        Text("Найкраще купити")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text(String(format: "%.2f ₴", bestSellUSD.sellRate))
                                .fontWeight(.bold)
                                .foregroundColor(Color.blue)
                            
                            Text(bestSellUSD.bankName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Divider()
            
            // EUR курси
            HStack {
                Text("EUR")
                    .font(.headline)
                    .foregroundColor(Color.blue)
                    .frame(width: 60, alignment: .leading)
                
                Spacer()
                
                if let bestBuyEUR = entry.widgetData.bestBuyRates["EUR"],
                   let bestSellEUR = entry.widgetData.bestSellRates["EUR"] {
                    
                    VStack(alignment: .leading) {
                        Text("Найкраще продати")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text(String(format: "%.2f ₴", bestBuyEUR.buyRate))
                                .fontWeight(.bold)
                                .foregroundColor(Color.green)
                            
                            Text(bestBuyEUR.bankName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading) {
                        Text("Найкраще купити")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text(String(format: "%.2f ₴", bestSellEUR.sellRate))
                                .fontWeight(.bold)
                                .foregroundColor(Color.blue)
                            
                            Text(bestSellEUR.bankName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Divider()
            
            // Інформація про оновлення даних
            HStack {
                Spacer()
                
                if !Calendar.current.isDateInToday(entry.widgetData.lastUpdated) {
                    Text("Дані не оновлено сьогодні!")
                        .font(.caption)
                        .foregroundColor(.red)
                } else {
                    Text("Дані оновлено: \(entry.widgetData.lastUpdated, style: .time)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding()
    }
}

// MARK: - Widget

struct CurrExWidget: Widget {
    let kind: String = "CurrExWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            CurrExWidgetEntryView(entry: entry)
                .widgetURL(URL(string: "currex://widget/rates"))
        }
        .configurationDisplayName("Курси валют")
        .description("Відображає поточні курси валют USD та EUR")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct CurrExWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        if #available(iOS 17.0, *) {
            // Використання нового containerBackground API для iOS 17+
            contentView
                .containerBackground(.fill.tertiary, for: .widget)
        } else {
            // Підтримка для iOS 16 та нижче
            contentView
                .padding()
                .background(Color.blue.opacity(0.1))
        }
    }
    
    private var contentView: some View {
            switch family {
            case .systemSmall:
                AnyView(SmallRateWidgetView(entry: entry))
            case .systemMedium:
                AnyView(MediumRateWidgetView(entry: entry))
            case .systemLarge:
                AnyView(LargeRateWidgetView(entry: entry))
            default:
                AnyView(SmallRateWidgetView(entry: entry))
            }
        }
}
// Додайте цей extension для умовного застосування модифікаторів
extension View {
    @ViewBuilder
    func `if`<TrueContent: View, FalseContent: View>(
        _ condition: Bool,
        @ViewBuilder then trueContent: (Self) -> TrueContent,
        @ViewBuilder else falseContent: (Self) -> FalseContent
    ) -> some View {
        if condition {
            trueContent(self)
        } else {
            falseContent(self)
        }
    }
}

// MARK: - Widget Bundle

@main
struct CurrExWidgets: WidgetBundle {
    var body: some Widget {
        CurrExWidget()
    }
}

//#Preview {
//    Group {
//        LargeRateWidgetView(entry: RateEntry(
//            date: Date(),
//            widgetData: WidgetExchangeRateData(
//                bestBuyRates: [
//                    "USD": WidgetExchangeRate(currencyType: "USD", buyRate: 38.5, sellRate: 39.2, bankName: "PrivatBank", timestamp: "2025-03-05T12:00:00Z"),
//                    "EUR": WidgetExchangeRate(currencyType: "EUR", buyRate: 41.3, sellRate: 42.1, bankName: "Raiffeisen", timestamp: "2025-03-05T12:00:00Z")
//                ],
//                bestSellRates: [
//                    "USD": WidgetExchangeRate(currencyType: "USD", buyRate: 38.2, sellRate: 38.9, bankName: "Raiffeisen", timestamp: "2025-03-05T12:00:00Z"),
//                    "EUR": WidgetExchangeRate(currencyType: "EUR", buyRate: 40.8, sellRate: 41.7, bankName: "Bestobmin", timestamp: "2025-03-05T12:00:00Z")
//                ],
//                lastUpdated: Date()
//            )
//        ))
//        .previewContext(WidgetPreviewContext(family: .systemLarge))
//        
//        MediumRateWidgetView(entry: RateEntry(
//            date: Date(),
//            widgetData: WidgetExchangeRateData(
//                bestBuyRates: [
//                    "USD": WidgetExchangeRate(currencyType: "USD", buyRate: 38.5, sellRate: 39.2, bankName: "PrivatBank", timestamp: "2025-03-05T12:00:00Z"),
//                    "EUR": WidgetExchangeRate(currencyType: "EUR", buyRate: 41.3, sellRate: 42.1, bankName: "Raiffeisen", timestamp: "2025-03-05T12:00:00Z")
//                ],
//                bestSellRates: [
//                    "USD": WidgetExchangeRate(currencyType: "USD", buyRate: 38.2, sellRate: 38.9, bankName: "Raiffeisen", timestamp: "2025-03-05T12:00:00Z"),
//                    "EUR": WidgetExchangeRate(currencyType: "EUR", buyRate: 40.8, sellRate: 41.7, bankName: "Bestobmin", timestamp: "2025-03-05T12:00:00Z")
//                ],
//                lastUpdated: Date()
//            )
//        ))
//        .previewContext(WidgetPreviewContext(family: .systemMedium))
//        
//        SmallRateWidgetView(entry: RateEntry(
//            date: Date(),
//            widgetData: WidgetExchangeRateData(
//                bestBuyRates: [
//                    "USD": WidgetExchangeRate(currencyType: "USD", buyRate: 38.5, sellRate: 39.2, bankName: "PrivatBank", timestamp: "2025-03-05T12:00:00Z"),
//                ],
//                bestSellRates: [
//                    "USD": WidgetExchangeRate(currencyType: "USD", buyRate: 38.2, sellRate: 38.9, bankName: "Raiffeisen", timestamp: "2025-03-05T12:00:00Z"),
//                ],
//                lastUpdated: Date()
//            )
//        ))
//        .previewContext(WidgetPreviewContext(family: .systemSmall))
//    }
//}
