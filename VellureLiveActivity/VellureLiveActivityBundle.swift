import WidgetKit
import SwiftUI

@main
struct VellureLiveActivityBundle: WidgetBundle {
    var body: some Widget {
        VellureLiveActivityWidget()
        VellureLockScreenWidget()
        VellureHomeScreenWidget()
    }
}
