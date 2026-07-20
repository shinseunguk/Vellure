import ActivityKit
import WidgetKit
import SwiftUI

struct VellureLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MemoAttributes.self) { context in
            LockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 8, height: 8)
                        Text("Vellure")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.renderType.capitalized)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.content)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(3)
                        .padding(.top, 4)
                }
            } compactLeading: {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 12, height: 12)
            } compactTrailing: {
                Text(context.state.content)
                    .font(.system(size: 12, weight: .bold))
                    .lineLimit(1)
                    .frame(maxWidth: 80)
            } minimal: {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 12, height: 12)
            }
        }
    }
}
