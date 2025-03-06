// File: CurrExWidgets.swift
import WidgetKit
import SwiftUI

@main
struct CurrExWidgets: WidgetBundle {
    var body: some Widget {
        CurrExWidget()
    }
}

// File: CurrExWidget.swift
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

// File: ExchangeRateWidgetView.swift
/// Main widget view
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
        .containerBackground(.background, for: .widget) // Key change to use containerBackground API
        .widgetURL(URL(string: "currex://widget/rates?currency=\(entry.currency)"))
    }
}

// File: ExchangeRateEntry.swift
/// Data model for widget
struct ExchangeRateEntry: TimelineEntry {
    /// Update date
    let date: Date
    
    /// Currency (USD, EUR, etc.)
    let currency: String
    
    /// Exchange rates for display in widget
    let rates: [SharedWidgetModels.ExchangeRate]
    
    /// Formatted update time
    var formattedUpdateTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "uk_UA")
        return formatter.string(from: date)
    }
    
    /// Best rate for selling currency
    var bestBuyRate: SharedWidgetModels.ExchangeRate? {
        rates.max(by: { $0.buyRate > $1.buyRate })
    }
        
    /// Best rate for buying currency
    var bestSellRate: SharedWidgetModels.ExchangeRate? {
        rates.min(by: { $0.sellRate > $1.sellRate })
    }
    
    /// Check if data is available
    var hasData: Bool {
        !rates.isEmpty
    }
}

// File: ExchangeRateProvider.swift
struct ExchangeRateProvider: TimelineProvider {
    typealias Entry = ExchangeRateEntry
    
    /// Widget settings
    let settings = SharedDataService.getWidgetSettings()
    
    /// Provides placeholder for widget preview
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
        
        return Entry(
            date: Date(),
            currency: settings.selectedCurrency,
            rates: placeholder
        )
    }
    
    /// Provides snapshot for widget
    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        // Use placeholder in preview mode
        if context.isPreview {
            completion(placeholder(in: context))
            return
        }
        
        // Otherwise get real data
        let currency = settings.selectedCurrency
        let rates = SharedDataService.getExchangeRates(for: currency)
        let date = SharedDataService.getLastUpdateTime() ?? Date()
        
        let entry = Entry(
            date: date,
            currency: currency,
            rates: rates
        )
        
        completion(entry)
    }
    
    /// Provides timeline for widget updates
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        // Get real data
        let currency = settings.selectedCurrency
        let rates = SharedDataService.getExchangeRates(for: currency)
        let date = SharedDataService.getLastUpdateTime() ?? Date()
        
        let entry = Entry(
            date: date,
            currency: currency,
            rates: rates
        )
        
        // Update widget every 30 minutes
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        
        // Create timeline with single entry
        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        
        completion(timeline)
    }
}

// File: SmallWidgetView.swift
/// Improved small widget view with localization and optimized spacing
struct SmallWidgetView: View {
    /// Data for display in the widget
    let entry: ExchangeRateEntry
    
    /// Buy rate color
    private let buyColor = Color("BuyColor")
    
    /// Sell rate color
    private let sellColor = Color("SellColor")
    
    var body: some View {
        VStack(spacing: 4) { // Reduced spacing to fit more content
            // Header with currency
            HStack {
                Text(entry.currency)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Display update time
                Text(NSLocalizedString("Widget.UpdatedAt", comment: "Updated label"))
                    .font(.system(size: 8)) // Smaller font
                    .foregroundColor(.secondary)
            }
            
            if entry.hasData {
                Spacer(minLength: 2)
                
                // Best buy rate
                if let bestBuy = entry.bestBuyRate {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(NSLocalizedString("Widget.BestToSell", comment: "Best to sell label"))
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        
                        HStack {
                            // Short bank name (first 4 chars + ellipsis if longer)
                            Text(bestBuy.bankName.count > 6 ? String(bestBuy.bankName.prefix(4)) + "..." : bestBuy.bankName)
                                .font(.caption)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Text(String(format: "%.2f", bestBuy.buyRate))
                                .font(.callout)
                                .fontWeight(.bold)
                                .foregroundColor(buyColor)
                        }
                    }
                    .padding(.vertical, 2)
                    .padding(.horizontal, 4)
                    .background(buyColor.opacity(0.1))
                    .cornerRadius(4)
                }
                
                // Best sell rate
                if let bestSell = entry.bestSellRate {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(NSLocalizedString("Widget.BestToBuy", comment: "Best to buy label"))
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        
                        HStack {
                            // Short bank name (first 4 chars + ellipsis if longer)
                            Text(bestSell.bankName.count > 6 ? String(bestSell.bankName.prefix(4)) + "..." : bestSell.bankName)
                                .font(.caption)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Text(String(format: "%.2f", bestSell.sellRate))
                                .font(.callout)
                                .fontWeight(.bold)
                                .foregroundColor(sellColor)
                        }
                    }
                    .padding(.vertical, 2)
                    .padding(.horizontal, 4)
                    .background(sellColor.opacity(0.1))
                    .cornerRadius(4)
                }
            } else {
                Spacer()
                
                Text(NSLocalizedString("Widget.NoData", comment: "No data text"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(NSLocalizedString("Widget.OpenAppToUpdate", comment: "Open app to update text"))
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            // Last updated time (only show if data exists)
            if entry.hasData {
                Text(entry.formattedUpdateTime)
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(8)
    }
}

// File: MediumWidgetView.swift
/// Improved medium widget view with localization and optimized spacing
struct MediumWidgetView: View {
    /// Data for display in the widget
    let entry: ExchangeRateEntry
    
    /// Buy rate color
    private let buyColor = Color("BuyColor")
    
    /// Sell rate color
    private let sellColor = Color("SellColor")
    
    var body: some View {
        VStack(spacing: 4) {
            // Header with currency
            HStack {
                Text(NSLocalizedString("Widget.Title", comment: "Exchange rates title"))
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Display update time
                Text("\(NSLocalizedString("Widget.UpdatedAt", comment: "Updated label")) \(entry.formattedUpdateTime)")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            
            if entry.hasData {
                // Rates table
                VStack(spacing: 0) {
                    // Table header
                    HStack {
                        Text(NSLocalizedString("Widget.BankName", comment: "Bank column header"))
                            .font(.system(size: 10))
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text(NSLocalizedString("Widget.Buy", comment: "Buy column header"))
                            .font(.system(size: 10))
                            .fontWeight(.medium)
                            .frame(width: 55, alignment: .trailing)
                        
                        Text(NSLocalizedString("Widget.Sell", comment: "Sell column header"))
                            .font(.system(size: 10))
                            .fontWeight(.medium)
                            .frame(width: 55, alignment: .trailing)
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.1))
                    
                    // Exchange rate data
                    ForEach(entry.rates.prefix(3)) { rate in // Limit to first 3 banks
                        HStack {
                            // Short bank name (first 8 chars)
                            Text(rate.bankName.count > 8 ? String(rate.bankName.prefix(8)) : rate.bankName)
                                .font(.system(size: 11))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .lineLimit(1)
                            
                            Text(String(format: "%.2f", rate.sellRate))
                                .font(.system(size: 11))
                                .fontWeight(.medium)
                                .foregroundColor(sellColor)
                                .frame(width: 55, alignment: .trailing)
                            
                            Text(String(format: "%.2f", rate.buyRate))
                                .font(.system(size: 11))
                                .fontWeight(.medium)
                                .foregroundColor(buyColor)
                                .frame(width: 55, alignment: .trailing)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        
                        // Add divider for all rows except the last
                        if rate.id != entry.rates.prefix(3).last?.id {
                            Divider()
                                .padding(.horizontal, 8)
                        }
                    }
                }
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(8)
                
                // Best rates
                HStack(spacing: 6) {
                    // Best sell rate
                    if let bestBuy = entry.bestBuyRate {
                        VStack(alignment: .leading, spacing: 0) {
                            Text(NSLocalizedString("Widget.BestToSell", comment: "Best to sell label"))
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Text(bestBuy.bankName.count > 8 ? String(bestBuy.bankName.prefix(8)) : bestBuy.bankName)
                                    .font(.system(size: 10))
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                Text(String(format: "%.2f", bestBuy.buyRate))
                                    .font(.callout)
                                    .fontWeight(.bold)
                                    .foregroundColor(buyColor)
                            }
                        }
                        .padding(.vertical, 3)
                        .padding(.horizontal, 6)
                        .background(buyColor.opacity(0.1))
                        .cornerRadius(6)
                        .frame(maxWidth: .infinity)
                    }
                    
                    // Best buy rate
                    if let bestSell = entry.bestSellRate {
                        VStack(alignment: .leading, spacing: 0) {
                            Text(NSLocalizedString("Widget.BestToBuy", comment: "Best to buy label"))
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Text(bestSell.bankName.count > 8 ? String(bestSell.bankName.prefix(8)) : bestSell.bankName)
                                    .font(.system(size: 10))
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                Text(String(format: "%.2f", bestSell.sellRate))
                                    .font(.callout)
                                    .fontWeight(.bold)
                                    .foregroundColor(sellColor)
                            }
                        }
                        .padding(.vertical, 3)
                        .padding(.horizontal, 6)
                        .background(sellColor.opacity(0.1))
                        .cornerRadius(6)
                        .frame(maxWidth: .infinity)
                    }
                }
            } else {
                // Display no data message
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
        .padding(10)
    }
}

// File: LargeWidgetView.swift
/// Improved large widget view with localization and optimized spacing
struct LargeWidgetView: View {
    /// Data for display in the widget
    let entry: ExchangeRateEntry
    
    /// Buy rate color
    private let buyColor = Color("BuyColor")
    
    /// Sell rate color
    private let sellColor = Color("SellColor")
    
    var body: some View {
        VStack(spacing: 8) {
            // Header with currency
            HStack {
                Text("Курс \(entry.currency)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Display update time
                Text("\(NSLocalizedString("Widget.UpdatedAt", comment: "Updated label")) \(entry.formattedUpdateTime)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if entry.hasData {
                // Best rates
                HStack(spacing: 8) {
                    // Best buy rate
                    VStack(alignment: .leading, spacing: 2) {
                        Text(NSLocalizedString("Widget.BestToSell", comment: "Best to sell label"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let bestBuy = entry.bestBuyRate {
                            Text(bestBuy.bankName)
                                .font(.subheadline)
                                .lineLimit(1)
                            
                            Text(String(format: "%.2f", bestBuy.buyRate))
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(buyColor)
                        } else {
                            Text(NSLocalizedString("Widget.NoData", comment: "No data text"))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(buyColor.opacity(0.1))
                    .cornerRadius(10)
                    
                    // Best sell rate
                    VStack(alignment: .leading, spacing: 2) {
                        Text(NSLocalizedString("Widget.BestToBuy", comment: "Best to buy label"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let bestSell = entry.bestSellRate {
                            Text(bestSell.bankName)
                                .font(.subheadline)
                                .lineLimit(1)
                            
                            Text(String(format: "%.2f", bestSell.sellRate))
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(sellColor)
                        } else {
                            Text(NSLocalizedString("Widget.NoData", comment: "No data text"))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(sellColor.opacity(0.1))
                    .cornerRadius(10)
                }
                .frame(height: 100)
                
                // Table with exchange rates
                VStack(spacing: 0) {
                    // Table header
                    HStack {
                        Text(NSLocalizedString("Widget.BankName", comment: "Bank column header"))
                            .font(.caption)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text(NSLocalizedString("Widget.Buy", comment: "Buy column header"))
                            .font(.caption)
                            .fontWeight(.medium)
                            .frame(width: 60, alignment: .trailing)
                        
                        Text(NSLocalizedString("Widget.Sell", comment: "Sell column header"))
                            .font(.caption)
                            .fontWeight(.medium)
                            .frame(width: 60, alignment: .trailing)
                        
                        Text(NSLocalizedString("Widget.Spread", comment: "Spread column header"))
                            .font(.caption)
                            .fontWeight(.medium)
                            .frame(width: 60, alignment: .trailing)
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.secondary.opacity(0.1))
                    
                    // Bank rates
                    ForEach(entry.rates) { rate in
                        HStack {
                            Text(rate.bankName)
                                .font(.subheadline)
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Text(String(format: "%.2f", rate.sellRate))
                                .font(.subheadline)
                                .foregroundColor(sellColor)
                                .frame(width: 60, alignment: .trailing)
                            
                            Text(String(format: "%.2f", rate.buyRate))
                                .font(.subheadline)
                                .foregroundColor(buyColor)
                                .frame(width: 60, alignment: .trailing)
                            
                            let spread = rate.sellRate - rate.buyRate
                            Text(String(format: "%.2f", spread))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(width: 60, alignment: .trailing)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        
                        // Add divider for all rows except the last
                        if rate.id != entry.rates.last?.id {
                            Divider()
                                .padding(.horizontal, 10)
                        }
                    }
                }
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(10)
                
                // Footer note
                Text(NSLocalizedString("Widget.TapForDetails", comment: "Tap for details text"))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            } else {
                // Show message if no data
                Spacer()
                
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    
                    Text(NSLocalizedString("Widget.NoData", comment: "No data text"))
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                    
                    Text(NSLocalizedString("Widget.OpenAppToUpdate", comment: "Open app to update text"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }
                
                Spacer()
            }
        }
        .padding(12)
    }
}

// Helper extension for conditional modifiers
extension View {
    @ViewBuilder
    func `if`<Content: View>(
        _ condition: Bool,
        transform: (Self) -> Content
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
