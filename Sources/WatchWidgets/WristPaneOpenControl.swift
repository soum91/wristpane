import AppIntents
import SwiftUI
import WidgetKit

struct WristPaneOpenControl: ControlWidget {
    static let kind = "com.soum91.wristpane.open"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: OpenDashboardIntent()) {
                Label("WristPane", systemImage: "square.grid.2x2.fill")
            }
        }
        .displayName("Open WristPane")
        .description("Open your custom Apple Watch dashboard.")
    }
}
