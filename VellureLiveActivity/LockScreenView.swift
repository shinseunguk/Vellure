import SwiftUI
import WidgetKit

struct LockScreenView: View {
    let context: ActivityViewContext<MemoAttributes>

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.accentColor)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 4) {
                Text("Vellure")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.accentColor)

                Text(context.state.content)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(16)
        .activityBackgroundTint(.black.opacity(0.85))
    }
}
