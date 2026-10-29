import AppIntents

/// Launches the owning application when a Control Center button is tapped.
struct OpenDashboardIntent: AppIntent {
    static var title: LocalizedStringResource = "Open WristPane"
    static var description = IntentDescription("Open the customizable watch dashboard.")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        .result()
    }
}
