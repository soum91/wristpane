import SwiftUI

struct PhoneSettingsView: View {
    @AppStorage("pane0") private var pane0 = "weather"
    @AppStorage("pane1") private var pane1 = "light"
    @AppStorage("pane2") private var pane2 = "room"
    @AppStorage("pane3") private var pane3 = "purifier"
    @AppStorage("pane4") private var pane4 = "battery"
    @AppStorage("pane5") private var pane5 = "music"
    @AppStorage("city") private var city = "sudbury"
    @State private var synced = false

    private var selections: [String] {
        [pane0, pane1, pane2, pane3, pane4, pane5]
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Your wrist, arranged your way", systemImage: "square.grid.2x2.fill")
                            .font(.title3.bold())
                        Text("Choose six tiles for your Apple Watch dashboard. Slots marked Connect are reserved for future app integrations and do not control devices yet.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                }

                Section("Dashboard slots") {
                    slotPicker(1, selection: $pane0)
                    slotPicker(2, selection: $pane1)
                    slotPicker(3, selection: $pane2)
                    slotPicker(4, selection: $pane3)
                    slotPicker(5, selection: $pane4)
                    slotPicker(6, selection: $pane5)
                }

                Section("Weather location") {
                    Picker("City", selection: $city) {
                        ForEach(PaneCity.allCases) { city in
                            Text(city.title).tag(city.rawValue)
                        }
                    }
                    Text("Weather uses Open-Meteo and the chosen city centre, not your precise GPS location.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Button {
                        WatchSync.shared.send(configuration: ["slots": selections, "city": city])
                        synced = true
                    } label: {
                        Label("Sync to Watch", systemImage: "applewatch.side.right")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    if synced {
                        Text("Settings queued for your paired Watch. Open WristPane there to view them.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("System integration") {
                    Label("Add WristPane from the watch face complication gallery", systemImage: "clock")
                    Label("Pin the WristPane widget in Smart Stack", systemImage: "square.stack")
                    Label("Add Open WristPane to Control Center", systemImage: "switch.2")
                }
            }
            .navigationTitle("WristPane")
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear { WatchSync.shared.activate() }
            .onChange(of: selections) { _, newValue in
                WatchSync.shared.send(configuration: ["slots": newValue, "city": city])
                synced = false
            }
            .onChange(of: city) { _, newValue in
                WatchSync.shared.send(configuration: ["slots": selections, "city": newValue])
                synced = false
            }
        }
    }

    private func slotPicker(_ number: Int, selection: Binding<String>) -> some View {
        Picker("Slot \(number)", selection: selection) {
            ForEach(PaneKind.allCases) { option in
                Label(option.title, systemImage: option.symbol).tag(option.rawValue)
            }
        }
    }
}
