import WidgetKit
import SwiftUI

@main
struct CurrExWidgets: WidgetBundle {
    var body: some Widget {
        CurrExWidget()
    }
}

struct CurrExWidget: Widget {
    /// Widget type identifier
    private let kind = "CurrExWidget"
    
    /// Widget configuration
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ExchangeRateProvider()) { entry in
            ExchangeRateWidgetView(entry: entry)
        }
        .configurationDisplayName(NSLocalizedString("Widget.Title", comment: "Widget display name"))
        .description(NSLocalizedString("Widget.Description", comment: "Widget description"))
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

/// Main view for the widget
struct ExchangeRateWidgetView: View {
    /// Widget size
    @Environment(\.widgetFamily) var family
    
    /// Data for display in widget
    var entry: ExchangeRateProvider.Entry
    
    var body: some View {
        // Select layout based on widget size
        Group {
            switch family {
            case .systemSmall:
                SmallWidgetView(entry: entry)
            case .systemMedium:
                MediumWidgetView(entry: entry)
            case .systemLarge:
                LargeWidgetView(entry: entry)
            default:
                MediumWidgetView(entry: entry)
            }
        }
        // Add containerBackground for iOS 17+
        .modifier(WidgetBackgroundModifier())
        .widgetURL(URL(string: "currex://widget/rates?currency=\(entry.currency)"))
    }
}

/// Small widget view
struct SmallWidgetView: View {
    /// Data for display
    let entry: ExchangeRateEntry
    
    /// Colors for rates
    private let buyColor = Color("BuyColor")
    private let sellColor = Color("SellColor")
    
    var body: some View {
        VStack(spacing: 4) {
            // Header with currency
            HStack {
                Text(entry.currency)
                    .font(.headline)
                    .fontWeight(.bold)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                
                Spacer()
            }
            
            if entry.hasData {
                Spacer(minLength: 0)
                
                // Best buy rate (highest buy rate - best to sell at)
                if let bestBuy = entry.bestBuyRate {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(NSLocalizedString("Widget.BestToSell", comment: "Best to sell label"))
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        
                        HStack {
                            Text(bestBuy.bankName)
                                .font(.system(size: 11))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            
                            Spacer()
                            
                            Text(String(format: "%.2f", bestBuy.buyRate))
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(buyColor)
                                .lineLimit(1)
                        }
                    }
                    .padding(.vertical, 3)
                    .padding(.horizontal, 6)
                    .background(buyColor.opacity(0.1))
                    .cornerRadius(6)
                }
                
                Spacer(minLength: 2)
                
                // Best sell rate (lowest sell rate - best to buy at)
                if let bestSell = entry.bestSellRate {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(NSLocalizedString("Widget.BestToBuy", comment: "Best to buy label"))
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        
                        HStack {
                            Text(bestSell.bankName)
                                .font(.system(size: 11))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            
                            Spacer()
                            
                            Text(String(format: "%.2f", bestSell.sellRate))
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(sellColor)
                                .lineLimit(1)
                        }
                    }
                    .padding(.vertical, 3)
                    .padding(.horizontal, 6)
                    .background(sellColor.opacity(0.1))
                    .cornerRadius(6)
                }
                
                Spacer(minLength: 0)
                
                // Last updated timestamp
                Text(entry.formattedUpdateTime)
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.top, 2)
            } else {
                // Display message if no data
                Spacer()
                
                Text(NSLocalizedString("Widget.NoData", comment: "No data text"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(NSLocalizedString("Widget.OpenAppToUpdate", comment: "Open app to update text"))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Spacer()
            }
        }
        .padding(8)
    }
}

/// Medium widget view
struct MediumWidgetView: View {
    /// Data for display
    let entry: ExchangeRateEntry
    
    /// Colors for rates
    private let buyColor = Color("BuyColor")
    private let sellColor = Color("SellColor")
    
    var body: some View {
        VStack(spacing: 4) {
            // Header with currency
            HStack {
                Text("Курс \(entry.currency)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .lineLimit(1)
                
                Spacer()
                
                // Display update time in a smaller font
                Text("\(NSLocalizedString("Widget.UpdatedAt", comment: "Updated label"))")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                    + Text(" \(entry.formattedUpdateTime)")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            if entry.hasData {
                // Best rates in two-column layout
                HStack(spacing: 8) {
                    // Best buy rate (highest buy rate - best to sell at)
                    if let bestBuy = entry.bestBuyRate {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(NSLocalizedString("Widget.BestToSell", comment: "Best to sell label"))
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Text(bestBuy.bankName)
                                    .font(.system(size: 11))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                
                                Spacer()
                                
                                Text(String(format: "%.2f", bestBuy.buyRate))
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(buyColor)
                            }
                        }
                        .padding(6)
                        .background(buyColor.opacity(0.1))
                        .cornerRadius(6)
                        .frame(maxWidth: .infinity)
                    }
                    
                    // Best sell rate (lowest sell rate - best to buy at)
                    if let bestSell = entry.bestSellRate {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(NSLocalizedString("Widget.BestToBuy", comment: "Best to buy label"))
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Text(bestSell.bankName)
                                    .font(.system(size: 11))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                
                                Spacer()
                                
                                Text(String(format: "%.2f", bestSell.sellRate))
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(sellColor)
                            }
                        }
                        .padding(6)
                        .background(sellColor.opacity(0.1))
                        .cornerRadius(6)
                        .frame(maxWidth: .infinity)
                    }
                }
                
                // Table with exchange rates
                VStack(spacing: 0) {
                    // Table header
                    HStack {
                        Text(NSLocalizedString("Widget.BankName", comment: "Bank column header"))
                            .font(.system(size: 10, weight: .medium))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text(NSLocalizedString("Widget.Buy", comment: "Buy column header"))
                            .font(.system(size: 10, weight: .medium))
                            .frame(width: 60, alignment: .trailing)
                        
                        Text(NSLocalizedString("Widget.Sell", comment: "Sell column header"))
                            .font(.system(size: 10, weight: .medium))
                            .frame(width: 60, alignment: .trailing)
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.secondary.opacity(0.1))
                    
                    // Bank rates - show up to 3 banks for medium widget
                    ForEach(Array(entry.rates.prefix(3))) { rate in
                        HStack {
                            Text(rate.bankName)
                                .font(.system(size: 11))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Text(String(format: "%.2f", rate.buyRate))
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(buyColor)
                                .frame(width: 60, alignment: .trailing)
                            
                            Text(String(format: "%.2f", rate.sellRate))
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(sellColor)
                                .frame(width: 60, alignment: .trailing)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        
                        // Add divider for all rows except the last
                        if rate.id != entry.rates.prefix(3).last?.id {
                            Divider()
                                .padding(.horizontal, 8)
                        }
                    }
                }
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(6)
                .padding(.top, 4)
            } else {
                // Display message if no data
                Spacer()
                
                Text(NSLocalizedString("Widget.NoData", comment: "No data text"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(NSLocalizedString("Widget.OpenAppToUpdate", comment: "Open app to update text"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        }
        .padding(8)
    }
}

/// View for large-sized widget
struct LargeWidgetView: View {
    /// Data for display
    let entry: ExchangeRateEntry
    
    /// Colors for rates
    private let buyColor = Color("BuyColor")
    private let sellColor = Color("SellColor")
    
    var body: some View {
        VStack(spacing: 8) {
            // Header with currency
            HStack {
                Text("Курс \(entry.currency)")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                // Display update time
                Text("\(NSLocalizedString("Widget.UpdatedAt", comment: "Updated label")) \(entry.formattedUpdateTime)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if entry.hasData {
                // Best rates
                HStack(spacing: 12) {
                    // Best buy rate (highest buy rate - best to sell at)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(NSLocalizedString("Widget.BestToSell", comment: "Best to sell label"))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        if let bestBuy = entry.bestBuyRate {
                            Text(bestBuy.bankName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text(String(format: "%.2f", bestBuy.buyRate))
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(buyColor)
                        } else {
                            Text(NSLocalizedString("Widget.NoData", comment: "No data placeholder"))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(buyColor.opacity(0.1))
                    .cornerRadius(10)
                    
                    // Best sell rate (lowest sell rate - best to buy at)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(NSLocalizedString("Widget.BestToBuy", comment: "Best to buy label"))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        if let bestSell = entry.bestSellRate {
                            Text(bestSell.bankName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text(String(format: "%.2f", bestSell.sellRate))
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(sellColor)
                        } else {
                            Text(NSLocalizedString("Widget.NoData", comment: "No data placeholder"))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(sellColor.opacity(0.1))
                    .cornerRadius(10)
                }
                .frame(height: 110)
                
                // Table with exchange rates
                VStack(spacing: 0) {
                    // Table header
                    HStack {
                        Text(NSLocalizedString("Widget.BankName", comment: "Bank column header"))
                            .font(.caption)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .minimumScaleFactor(0.8)
                        
                        Text(NSLocalizedString("Widget.Buy", comment: "Buy column header"))
                            .font(.caption)
                            .fontWeight(.medium)
                            .frame(width: 60, alignment: .trailing)
                            .minimumScaleFactor(0.8)
                        
                        Text(NSLocalizedString("Widget.Sell", comment: "Sell column header"))
                            .font(.caption)
                            .fontWeight(.medium)
                            .frame(width: 60, alignment: .trailing)
                            .minimumScaleFactor(0.8)
                        
                        Text(NSLocalizedString("Widget.Spread", comment: "Spread column header"))
                            .font(.caption)
                            .fontWeight(.medium)
                            .frame(width: 60, alignment: .trailing)
                            .minimumScaleFactor(0.8)
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.secondary.opacity(0.1))
                    
                    // Bank rates
                    ForEach(entry.rates) { rate in
                        HStack {
                            Text(rate.bankName)
                                .font(.subheadline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .minimumScaleFactor(0.6)
                            
                            Text(String(format: "%.2f", rate.buyRate))
                                .font(.subheadline)
                                .foregroundColor(buyColor)
                                .frame(width: 60, alignment: .trailing)
                                .minimumScaleFactor(0.8)
                            
                            Text(String(format: "%.2f", rate.sellRate))
                                .font(.subheadline)
                                .foregroundColor(sellColor)
                                .frame(width: 60, alignment: .trailing)
                                .minimumScaleFactor(0.8)
                            
                            let spread = rate.sellRate - rate.buyRate
                            Text(String(format: "%.2f", spread))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(width: 60, alignment: .trailing)
                                .minimumScaleFactor(0.8)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        
                        // Add divider for all rows except the last
                        if rate.id != entry.rates.last?.id {
                            Divider()
                                .padding(.horizontal, 12)
                        }
                    }
                }
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(10)
                
                // Note
                HStack {
                    Text(NSLocalizedString("Widget.TapForDetails", comment: "Tap for details text"))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 4)
            } else {
                // Display message if no data
                Spacer()
                
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    
                    Text(NSLocalizedString("Widget.NoData", comment: "No data text"))
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                    
                    Text(NSLocalizedString("Widget.OpenAppToUpdate", comment: "Open app to update text"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                
                Spacer()
            }
        }
        .padding(12)
    }
}

// MARK: - Custom View Modifiers

/// Applies the appropriate widget background based on iOS version
struct WidgetBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.containerBackground(for: .widget) {
                Color(.systemBackground)
            }
        } else {
            content
        }
    }
}

// MARK: - Data Model
/// Data model for the widget
struct ExchangeRateEntry: TimelineEntry {
    /// Date when the data was updated
    let date: Date
    
    /// Currency code (USD, EUR, etc.)
    let currency: String
    
    /// Exchange rates to display in the widget
    let rates: [SharedWidgetModels.ExchangeRate]
    
    /// Best buy rate from main app calculation
    let bestBuyRate: SharedWidgetModels.ExchangeRate?
    
    /// Best sell rate from main app calculation
    let bestSellRate: SharedWidgetModels.ExchangeRate?
    
    /// Formatted update time
    var formattedUpdateTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "uk_UA")
        return formatter.string(from: date)
    }
    
    /// Check if data is available
    var hasData: Bool {
        return !rates.isEmpty
    }
}

// MARK: - Data Provider
/// Data provider for the widget
struct ExchangeRateProvider: TimelineProvider {
    typealias Entry = ExchangeRateEntry
    
    /// Widget settings
    private let settings = SharedDataService.getWidgetSettings()
    
    /// Provides placeholder data for widget preview
    /// - Parameter context: Widget context
    /// - Returns: Placeholder entry for display in widget
    func placeholder(in context: Context) -> Entry {
        // Create placeholder with sample data
        let placeholder = [
            SharedWidgetModels.ExchangeRate(
                currency: "USD",
                bankName: "PrivatBank",
                buyRate: 38.5,
                sellRate: 39.2,
                timestamp: ""
            ),
            SharedWidgetModels.ExchangeRate(
                currency: "USD",
                bankName: "Bestobmin",
                buyRate: 38.7,
                sellRate: 39.1,
                timestamp: ""
            ),
            SharedWidgetModels.ExchangeRate(
                currency: "USD",
                bankName: "Raiffeisen",
                buyRate: 38.3,
                sellRate: 38.9,
                timestamp: ""
            )
        ]
        
        // Best buy rate sample (Bestobmin has highest buy rate)
        let bestBuySample = SharedWidgetModels.ExchangeRate(
            currency: "USD",
            bankName: "Bestobmin",
            buyRate: 38.7,
            sellRate: 39.1,
            timestamp: ""
        )
        
        // Best sell rate sample (Raiffeisen has lowest sell rate)
        let bestSellSample = SharedWidgetModels.ExchangeRate(
            currency: "USD",
            bankName: "Raiffeisen",
            buyRate: 38.3,
            sellRate: 38.9,
            timestamp: ""
        )
        
        return Entry(
            date: Date(),
            currency: settings.selectedCurrency,
            rates: placeholder,
            bestBuyRate: bestBuySample,
            bestSellRate: bestSellSample
        )
    }
    
    /// Provides a snapshot of data for widget display
    /// - Parameters:
    ///   - context: Widget context
    ///   - completion: Closure to receive entry
    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        // Use placeholder for preview
        if context.isPreview {
            completion(placeholder(in: context))
            return
        }
        
        // Get real data
        let currency = settings.selectedCurrency
        let rates = SharedDataService.getExchangeRates(for: currency)
        let date = SharedDataService.getLastUpdateTime() ?? Date()
        
        // Get best rates directly from main app data
        let bestBuyRate = SharedDataService.getBestBuyRate(for: currency)
        let bestSellRate = SharedDataService.getBestSellRate(for: currency)
        
        let entry = Entry(
            date: date,
            currency: currency,
            rates: rates,
            bestBuyRate: bestBuyRate,
            bestSellRate: bestSellRate
        )
        
        completion(entry)
    }
    
    /// Provides a timeline of entries for widget updates
    /// - Parameters:
    ///   - context: Widget context
    ///   - completion: Closure to receive timeline
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        // Get real data
        let currency = settings.selectedCurrency
        let rates = SharedDataService.getExchangeRates(for: currency)
        let date = SharedDataService.getLastUpdateTime() ?? Date()
        
        // Get best rates directly from main app data
        let bestBuyRate = SharedDataService.getBestBuyRate(for: currency)
        let bestSellRate = SharedDataService.getBestSellRate(for: currency)
        
        let entry = Entry(
            date: date,
            currency: currency,
            rates: rates,
            bestBuyRate: bestBuyRate,
            bestSellRate: bestSellRate
        )
        
        // Update widget every 30 minutes
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        
        // Create timeline with single entry
        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        
        completion(timeline)
    }
}
