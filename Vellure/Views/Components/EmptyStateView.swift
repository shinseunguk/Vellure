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
                Text("메모가 없습니다")
                    .font(.system(size: 19, weight: .heavy))
                    .foregroundStyle(Theme.textPrimary)

                Text("첫 번째 메모를 작성하고\n잠금화면에서 확인해보세요")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Button(action: onCreateTap) {
                Text("새 메모 작성")
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
