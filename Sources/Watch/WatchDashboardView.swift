import SwiftUI
import WatchKit

struct WatchDashboardView: View {
    @State private var panes: [PaneKind] = PaneKind.initial
    @State private var city: PaneCity = .sudbury
    @State private var temperature: Double?
    @State private var weatherError = false
    @State private var batteryLevel: Float = -1
    @AppStorage("flowLiquidMotion") private var flowLiquidMotion = true
    @State private var showControls = false

    private let columns = [GridItem(.flexible(), spacing: 7), GridItem(.flexible(), spacing: 7)]

    var body: some View {
        FlowFusionWatchFace(
            temperature: temperature,
            batteryLevel: batteryLevel,
            motionEnabled: flowLiquidMotion
        )
        .ignoresSafeArea()
        .persistentSystemOverlays(.hidden)
        .toolbarVisibility(.hidden, for: .statusBar)
        .accessibilityLabel("Flow Fusion face with live time, battery, workout shortcut and temperature")
        .onLongPressGesture(minimumDuration: 0.7) {
            showControls = true
        }
        .sheet(isPresented: $showControls) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("WristPane")
                        .font(.headline)

                    Toggle("Animate Flow background", isOn: $flowLiquidMotion)

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

                    Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"))")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 8)
            }
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


// Flow Fusion combines the Siri Modular information arrangement with the visual
// language of the Flow face. This is a live WristPane app screen, not a native
// ClockKit system watch face. WatchOS suspends offscreen app animation.
private struct FlowFusionWatchFace: View {
    let temperature: Double?
    let batteryLevel: Float
    let motionEnabled: Bool

    private static let clockFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter
    }()

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE MMM d"
        return formatter
    }()

    private var batteryPercentage: Int? {
        guard batteryLevel >= 0 else { return nil }
        return Int((batteryLevel * 100).rounded())
    }

    private var batteryLabel: String {
        batteryPercentage.map(String.init) ?? "--"
    }

    private var temperatureLabel: String {
        temperature.map { "\(Int($0.rounded()))°" } ?? "--"
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                FlowLiquidBackground(isAnimated: motionEnabled)

                TimelineView(.periodic(from: .now, by: 1)) { timeline in
                    VStack(spacing: 2) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .shadow(color: .white.opacity(0.8), radius: 3)

                        Text(Self.dateFormatter.string(from: timeline.date).uppercased())
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .tracking(0.3)

                        Spacer(minLength: 3)

                        Text(Self.clockFormatter.string(from: timeline.date))
                            .font(.system(size: geometry.size.width * 0.34, weight: .light, design: .rounded))
                            .tracking(-3)
                            .minimumScaleFactor(0.65)
                            .lineLimit(1)
                            .foregroundStyle(
                                .linearGradient(
                                    colors: [Color.white.opacity(0.95), Color(red: 0.91, green: 1.0, blue: 0.23).opacity(0.86)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color.white.opacity(0.55), radius: 7)
                            .frame(maxWidth: .infinity)

                        Spacer(minLength: 3)

                        HStack(spacing: 7) {
                            complicationRing(batteryLabel, symbol: "battery.100percent")
                            complicationRing(nil, symbol: "figure.run")
                            complicationRing(temperatureLabel, symbol: "thermometer.medium")
                        }
                        .padding(.horizontal, 7)
                        .frame(height: 62)
                        .frame(maxWidth: .infinity)
                        .background(.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .strokeBorder(.white.opacity(0.22), lineWidth: 0.7)
                        }
                    }
                    .foregroundStyle(Color(red: 0.93, green: 1.0, blue: 0.42))
                    .padding(.horizontal, 9)
                    .padding(.top, 9)
                    .padding(.bottom, 12)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .strokeBorder(.white.opacity(0.27), lineWidth: 0.7)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func complicationRing(_ value: String?, symbol: String) -> some View {
        ZStack {
            Circle()
                .fill(.black.opacity(0.10))
            Circle()
                .strokeBorder(.white.opacity(0.65), lineWidth: 3)
                .padding(2)

            if let value {
                VStack(spacing: 1) {
                    Text(value)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Image(systemName: symbol)
                        .font(.system(size: 8, weight: .medium))
                }
            } else {
                Image(systemName: symbol)
                    .font(.system(size: 24, weight: .medium))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 49)
        .accessibilityLabel(value ?? "Workout")
    }
}

// Three translucent radial blooms are continuously redrawn while the app is
// foregrounded. Animation automatically pauses for Reduce Motion or when toggled off.
private struct FlowLiquidBackground: View {
    let isAnimated: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.35, green: 0.60, blue: 0.01),
                    Color(red: 0.63, green: 0.90, blue: 0.01),
                    Color(red: 0.35, green: 0.69, blue: 0.01)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            TimelineView(.animation(minimumInterval: 1.0 / 15.0, paused: !isAnimated || reduceMotion)) { frame in
                Canvas { graphics, size in
                    let seconds = (isAnimated && !reduceMotion) ? frame.date.timeIntervalSinceReferenceDate : 0.0
                    let w = size.width
                    let h = size.height

                    let blooms: [(CGPoint, CGFloat, Color)] = [
                        (
                            CGPoint(
                                x: w * (0.22 + 0.15 * CGFloat(sin(seconds * 0.35))),
                                y: h * (0.31 + 0.16 * CGFloat(cos(seconds * 0.23)))
                            ),
                            w * 0.76,
                            Color(red: 0.98, green: 1.0, blue: 0.24).opacity(0.76)
                        ),
                        (
                            CGPoint(
                                x: w * (0.77 + 0.13 * CGFloat(cos(seconds * 0.28))),
                                y: h * (0.66 + 0.18 * CGFloat(sin(seconds * 0.30)))
                            ),
                            w * 0.72,
                            Color(red: 0.93, green: 1.0, blue: 0.02).opacity(0.58)
                        ),
                        (
                            CGPoint(
                                x: w * (0.54 + 0.22 * CGFloat(sin(seconds * 0.18))),
                                y: h * (0.89 + 0.11 * CGFloat(cos(seconds * 0.39)))
                            ),
                            w * 0.68,
                            Color(red: 0.18, green: 0.46, blue: 0.01).opacity(0.48)
                        )
                    ]

                    for (center, radius, tint) in blooms {
                        let circle = Path(ellipseIn: CGRect(
                            x: center.x - radius,
                            y: center.y - radius,
                            width: radius * 2,
                            height: radius * 2
                        ))
                        graphics.fill(
                            circle,
                            with: .radialGradient(
                                Gradient(colors: [tint, tint.opacity(0)]),
                                center: center,
                                startRadius: 0,
                                endRadius: radius
                            )
                        )
                    }

                    let crescentCenter = CGPoint(
                        x: w * (0.60 + 0.09 * CGFloat(cos(seconds * 0.17))),
                        y: h * (0.50 + 0.09 * CGFloat(sin(seconds * 0.20)))
                    )
                    let crescent = Path(ellipseIn: CGRect(
                        x: crescentCenter.x - w * 0.49,
                        y: crescentCenter.y - h * 0.35,
                        width: w * 0.98,
                        height: h * 0.70
                    ))
                    graphics.stroke(crescent, with: .color(.white.opacity(0.18)), lineWidth: 14)
                }
                .blur(radius: 8)
            }

            LinearGradient(
                colors: [.white.opacity(0.16), .clear, .black.opacity(0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .accessibilityHidden(true)
    }
}
