import WidgetKit
import SwiftUI

@main
struct WristPaneWidgetBundle: WidgetBundle {
    var body: some Widget {
        WristPaneComplication()
        WristPaneOpenControl()
    }
}
