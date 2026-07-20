import SwiftUI

struct EmptyStateView: View {
    let onCreateTap: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Circle()
                .stroke(Theme.divider, lineWidth: 1)
                .frame(width: 76, height: 76)
                .overlay {
                    Circle()
                        .fill(Theme.accent)
                        .frame(width: 12, height: 12)
                }

            VStack(spacing: 8) {
                Text("empty.title")
                    .font(.system(size: 19, weight: .heavy))
                    .foregroundStyle(Theme.textPrimary)

                Text("empty.description")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Button(action: onCreateTap) {
                Text("empty.cta")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(Theme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }
}
