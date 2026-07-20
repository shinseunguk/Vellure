import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    let onComplete: () -> Void

    private let pages: [(icon: String, title: String, description: String)] = [
        (
            "note.text",
            "잠금화면 메모",
            "메모를 잠금화면에 고정하세요.\n중요한 내용을 언제든 확인할 수 있습니다."
        ),
        (
            "checklist",
            "다양한 콘텐츠",
            "일반 메모, 체크리스트, D-day,\n카운트다운, 진행바까지 지원합니다."
        ),
        (
            "mic.fill",
            "Siri & 단축어",
            "\"벨루어에 메모 추가\"로\n음성으로 빠르게 메모를 남기세요."
        ),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    pageView(pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 340)

            pageIndicator
                .padding(.top, 24)

            Spacer()

            Button {
                if currentPage < pages.count - 1 {
                    withAnimation { currentPage += 1 }
                } else {
                    onComplete()
                }
            } label: {
                Text(currentPage < pages.count - 1 ? "다음" : "시작하기")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Theme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)

            if currentPage < pages.count - 1 {
                Button("건너뛰기") {
                    onComplete()
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
                .padding(.bottom, 24)
            } else {
                Color.clear.frame(height: 46)
            }
        }
        .background(Theme.background)
    }

    private func pageView(_ page: (icon: String, title: String, description: String)) -> some View {
        VStack(spacing: 20) {
            RoundedRectangle(cornerRadius: 28)
                .fill(Theme.accent.opacity(0.12))
                .frame(width: 96, height: 96)
                .overlay {
                    Image(systemName: page.icon)
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                }

            Text(page.title)
                .font(.system(size: 26, weight: .heavy))
                .foregroundStyle(Theme.textPrimary)

            Text(page.description)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(.horizontal, 32)
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? Theme.accent : Theme.divider)
                    .frame(width: index == currentPage ? 24 : 8, height: 8)
                    .animation(.easeInOut(duration: 0.25), value: currentPage)
            }
        }
    }
}
