import AppIntents
import SwiftUI
import WidgetKit
import WatchKit

enum PaneComplicationContent: String, AppEnum {
    case weather
    case battery
    case time

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "WristPane content"
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .weather: "Weather",
        .battery: "Battery",
        .time: "Time"
    ]

    var symbol: String {
        switch self {
        case .weather: return "cloud.sun.fill"
        case .battery: return "battery.100percent"
        case .time: return "clock.fill"
        }
    }
}

struct PaneComplicationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "WristPane"
    static var description = IntentDescription("Choose the information shown in this complication.")

    @Parameter(title: "Content", default: .weather)
    var content: PaneComplicationContent

    @Parameter(title: "Weather city", default: .sudbury)
    var city: PaneWeatherCity
}

enum PaneWeatherCity: String, AppEnum {
    case sudbury
    case toronto
    case mississauga

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "City"
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .sudbury: "Sudbury", .toronto: "Toronto", .mississauga: "Mississauga"
    ]

    var city: PaneCity { PaneCity(rawValue: rawValue) ?? .sudbury }
}

struct PaneEntry: TimelineEntry {
    let date: Date
    let intent: PaneComplicationIntent
    let temperature: Double?
}

struct PaneProvider: AppIntentTimelineProvider {
    func recommendations() -> [AppIntentRecommendation<PaneComplicationIntent>] {
        // watchOS 26+ lets the person configure each complication directly.
        []
    }

    func placeholder(in context: Context) -> PaneEntry {
        PaneEntry(date: .now, intent: PaneComplicationIntent(), temperature: 18)
    }

    func snapshot(for configuration: PaneComplicationIntent, in context: Context) async -> PaneEntry {
        await entry(for: configuration)
    }

    func timeline(for configuration: PaneComplicationIntent, in context: Context) async -> Timeline<PaneEntry> {
        let item = await entry(for: configuration)
        return Timeline(entries: [item], policy: .after(Date().addingTimeInterval(30 * 60)))
    }

    private func entry(for configuration: PaneComplicationIntent) async -> PaneEntry {
        let value: Double?
        if configuration.content == .weather {
            value = try? await WeatherProvider.currentTemperature(in: configuration.city.city)
        } else {
            value = nil
        }
        if configuration.content == .battery {
            WKInterfaceDevice.current().isBatteryMonitoringEnabled = true
        }
        return PaneEntry(date: .now, intent: configuration, temperature: value)
    }
}

struct WristPaneComplication: Widget {
    let kind = "com.soum91.wristpane.complication"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: PaneComplicationIntent.self, provider: PaneProvider()) { entry in
            PaneComplicationView(entry: entry)
        }
        .configurationDisplayName("WristPane")
        .description("Configurable weather, battery and time on your watch face or Smart Stack.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryCorner, .accessoryInline])
    }
}

struct PaneComplicationView: View {
    @Environment(\.widgetFamily) private var family
    let entry: PaneEntry

    private var value: String {
        switch entry.intent.content {
        case .weather:
            return entry.temperature.map { "\(Int($0.rounded()))°" } ?? "--"
        case .battery:
            let battery = WKInterfaceDevice.current().batteryLevel
            return battery >= 0 ? "\(Int(battery * 100))%" : "--"
        case .time:
            return DateFormatter.localizedString(from: entry.date, dateStyle: .none, timeStyle: .short)
        }
    }

    var body: some View {
        Group {
            switch family {
            case .accessoryInline:
                Label(value, systemImage: entry.intent.content.symbol)
            case .accessoryCircular, .accessoryCorner:
                VStack(spacing: 2) {
                    Image(systemName: entry.intent.content.symbol)
                    Text(value).font(.caption2.bold()).minimumScaleFactor(0.6).lineLimit(1)
                }
            default:
                HStack(spacing: 8) {
                    Image(systemName: entry.intent.content.symbol)
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.intent.content == .weather ? entry.intent.city.city.title : "WristPane")
                            .font(.caption2)
                        Text(value)
                            .font(.headline)
                    }
                }
            }
        }
        .containerBackground(.clear, for: .widget)
    }
}
