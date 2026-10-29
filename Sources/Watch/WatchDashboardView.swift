import SwiftUI
import WatchKit

struct WatchDashboardView: View {
    @State private var panes: [PaneKind] = PaneKind.initial
    @State private var city: PaneCity = .sudbury
    @State private var temperature: Double?
    @State private var weatherError = false
    @State private var batteryLevel: Float = -1

    private let columns = [GridItem(.flexible(), spacing: 7), GridItem(.flexible(), spacing: 7)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("WristPane")
                        .font(.headline)
                    Spacer(minLength: 4)
                    Image(systemName: "sparkles")
                        .foregroundStyle(.cyan)
                }

                HStack(spacing: 5) {
                    Image(systemName: "location.fill")
                    Text(city.title)
                }
                .font(.caption2)
                .foregroundStyle(.secondary)

                LazyVGrid(columns: columns, spacing: 7) {
                    ForEach(Array(panes.enumerated()), id: \.offset) { _, pane in
                        paneTile(pane)
                    }
                }

                Text("Edit tiles in the WristPane iPhone app")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 6)
        }
        .task {
            loadSavedSettings()
            WKInterfaceDevice.current().isBatteryMonitoringEnabled = true
            batteryLevel = WKInterfaceDevice.current().batteryLevel
            WatchSync.shared.activate { payload in
                if let slots = payload["slots"] as? [String] {
                    UserDefaults.standard.set(slots, forKey: "watchSlots")
                }
                if let cityName = payload["city"] as? String {
                    UserDefaults.standard.set(cityName, forKey: "watchCity")
                }
                loadSavedSettings()
                Task { await refreshWeather() }
            }
            await refreshWeather()
        }
    }

    @ViewBuilder
    private func paneTile(_ kind: PaneKind) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: kind.symbol)
                .font(.title3)
                .foregroundStyle(kind == .weather ? .cyan : .primary)

            Spacer(minLength: 0)

            switch kind {
            case .weather:
                Text(temperature.map { "\(Int($0.rounded()))°" } ?? (weatherError ? "Offline" : "…"))
                    .font(.headline)
                    .lineLimit(1)
            case .battery:
                Text(batteryLevel >= 0 ? "\(Int(batteryLevel * 100))%" : "--")
                    .font(.headline)
            case .clock:
                Text(Date.now, style: .time)
                    .font(.caption.bold())
            default:
                Text("Connect")
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
            }

            Text(kind.title)
                .font(.system(size: 11, weight: .medium))
                .lineLimit(1)
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 91, maxHeight: 91, alignment: .leading)
        .glassEffect(.regular, in: .rect(cornerRadius: 18))
        .accessibilityElement(children: .combine)
    }

    private func loadSavedSettings() {
        if let names = UserDefaults.standard.stringArray(forKey: "watchSlots") {
            let parsed = names.compactMap(PaneKind.init(rawValue:))
            if !parsed.isEmpty { panes = parsed }
        }
        if let name = UserDefaults.standard.string(forKey: "watchCity"),
           let saved = PaneCity(rawValue: name) {
            city = saved
        }
    }

    private func refreshWeather() async {
        do {
            temperature = try await WeatherProvider.currentTemperature(in: city)
            weatherError = false
        } catch {
            weatherError = true
        }
    }
}
