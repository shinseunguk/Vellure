import SwiftUI
import VellureCore

public struct OnboardingView: View {
    private struct Page {
        let icon: String
        let titleKey: String
        let descKey: String
    }

    @State private var currentPage = 0
    let onComplete: () -> Void

    private let pages: [Page] = [
        Page(icon: "note.text", titleKey: "onboarding.page1.title", descKey: "onboarding.page1.desc"),
        Page(icon: "checklist", titleKey: "onboarding.page2.title", descKey: "onboarding.page2.desc"),
        Page(icon: "mic.fill", titleKey: "onboarding.page3.title", descKey: "onboarding.page3.desc")
    ]

    public init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
    }

    public var body: some View {
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
                Text(currentPage < pages.count - 1 ? "onboarding.next" : "onboarding.start")
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
                Button("onboarding.skip") {
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

    private func pageView(_ page: Page) -> some View {
        VStack(spacing: 20) {
            RoundedRectangle(cornerRadius: 28)
                .fill(Theme.accent.opacity(0.12))
                .frame(width: 96, height: 96)
                .overlay {
                    Image(systemName: page.icon)
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                }

            Text(LocalizedStringKey(page.titleKey))
                .font(.system(size: 26, weight: .heavy))
                .foregroundStyle(Theme.textPrimary)

            Text(LocalizedStringKey(page.descKey))
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
