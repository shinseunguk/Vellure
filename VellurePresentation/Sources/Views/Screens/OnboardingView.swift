import SwiftUI
import VellureCore
import VellureData

// swiftlint:disable:next type_body_length
public struct OnboardingView: View {
    @Environment(MemoRepository.self) private var repository
    @State private var currentPage = 0
    @State private var firstMemoText = ""
    let onComplete: () -> Void

    private let totalPages = 4

    public init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Dot indicator at top
            pageIndicator
                .padding(.top, 16)

            Spacer()

            // Pages
            TabView(selection: $currentPage) {
                page1LockScreen.tag(0)
                page2Permission.tag(1)
                page3Siri.tag(2)
                page4FirstMemo.tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea(.keyboard, edges: .bottom)

            Spacer()

            // CTA button
            Button {
                if currentPage < totalPages - 1 {
                    withAnimation { currentPage += 1 }
                } else {
                    publishFirstMemo()
                    onComplete()
                }
            } label: {
                Text(ctaText)
                    .font(.system(size: 15.5, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Theme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)

            // Skip button
            if currentPage < totalPages - 1 {
                Button("onboarding.skip") {
                    onComplete()
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
                .padding(.bottom, 40)
            } else {
                Color.clear.frame(height: 53)
            }
        }
        .background(Theme.background)
    }

    private var ctaText: String {
        switch currentPage {
        case 0: String(localized: "onboarding.cta.start")
        case 1: String(localized: "onboarding.cta.allow")
        case 2: String(localized: "onboarding.cta.siri")
        case 3: String(localized: "onboarding.cta.publish")
        default: ""
        }
    }

    private func publishFirstMemo() {
        let trimmed = firstMemoText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let memo = repository.create(
            content: trimmed,
            displayMode: .autoClear,
            clearTrigger: .hours,
            clearAfterHours: 12
        )

        if LiveActivityService.shared.isSupported,
           let activityId = LiveActivityService.shared.start(memo: memo) {
            repository.update(memo, activityId: activityId)
        }
    }

    // MARK: - Page Indicator

    private var pageIndicator: some View {
        HStack(spacing: 7) {
            ForEach(0..<totalPages, id: \.self) { index in
                Capsule()
                    .fill(index <= currentPage ? Theme.accent : Theme.divider)
                    .frame(width: index == currentPage ? 22 : 6, height: 6)
                    .animation(.easeInOut(duration: 0.25), value: currentPage)
            }
        }
    }

    // MARK: - Page 1: Lock Screen Hero

    private var page1LockScreen: some View {
        VStack(spacing: 24) {
            // Lock screen mockup
            VStack(spacing: 14) {
                VStack(spacing: 2) {
                    Text("onboarding.hero.date")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.6))
                    Text("9:41")
                        .font(.system(size: 38, weight: .bold))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                }

                // D-day card
                lockActivityCard(
                    typeLabel: "D-day",
                    content: String(localized: "onboarding.hero.dday"),
                    value: "D-12",
                    color: Color(red: 239 / 255, green: 150 / 255, blue: 69 / 255)
                )

                // Countdown card
                lockActivityCard(
                    typeLabel: String(localized: "type.countdown"),
                    content: String(localized: "onboarding.hero.countdown"),
                    value: "02:15:00",
                    color: Color(red: 31 / 255, green: 169 / 255, blue: 124 / 255)
                )
            }
            .padding(22)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.11, green: 0.23, blue: 0.18),
                                Color(red: 0.05, green: 0.12, blue: 0.08),
                                Color(red: 0.03, green: 0.08, blue: 0.06)
                            ],
                            center: UnitPoint(x: 0.5, y: -0.1),
                            startRadius: 0,
                            endRadius: 300
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .frame(width: 210)

            Text("onboarding.page1.title")
                .font(.system(size: 26, weight: .heavy))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)

            Text("onboarding.page1.desc")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .frame(maxWidth: 290)
        }
        .padding(.horizontal, 30)
    }

    private func lockActivityCard(typeLabel: String, content: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 6) {
                Circle().fill(color).frame(width: 5, height: 5)
                Text("Vellure · \(typeLabel)")
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundStyle(color)
            }
            HStack {
                Text(content)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer()
                Text(value)
                    .font(.system(size: 19, weight: .heavy))
                    .foregroundStyle(color)
                    .monospacedDigit()
            }
        }
        .padding(11)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(.black.opacity(0.55))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(.white.opacity(0.12), lineWidth: 1)
                )
        )
    }

    // MARK: - Page 2: Permission

    private var page2Permission: some View {
        VStack(spacing: 24) {
            // Permission dialog mockup
            VStack(spacing: 0) {
                VStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Theme.accent.opacity(0.15))
                        .frame(width: 40, height: 40)
                        .overlay {
                            Circle()
                                .fill(Theme.accent)
                                .frame(width: 9, height: 9)
                        }

                    Text("onboarding.perm.title")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)

                    Text("onboarding.perm.body")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }
                .padding(18)

                Divider()

                HStack(spacing: 0) {
                    Text("onboarding.perm.deny")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)

                    Divider().frame(height: 40)

                    Text("onboarding.perm.allow")
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundStyle(Theme.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                }
            }
            .background(Theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Theme.divider, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.1), radius: 16, y: 8)
            .frame(width: 230)

            Text("onboarding.page2.title")
                .font(.system(size: 26, weight: .heavy))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)

            Text("onboarding.page2.desc")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .frame(maxWidth: 290)
        }
        .padding(.horizontal, 30)
    }

    // MARK: - Page 3: Siri

    private var page3Siri: some View {
        VStack(spacing: 24) {
            // Siri voice demo
            VStack(spacing: 12) {
                HStack(spacing: 4) {
                    ForEach(0..<4, id: \.self) { i in
                        SiriBar(delay: Double(i) * 0.2)
                    }
                }
                .frame(height: 34)

                // Speech bubble
                Text("onboarding.siri.bubble")
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(10)
                    .frame(maxWidth: .infinity)
                    .background(.white.opacity(0.09))
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                HStack(spacing: 6) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color(red: 0.36, green: 0.86, blue: 0.6))
                    Text("onboarding.siri.done")
                        .font(.system(size: 10.5, weight: .bold))
                        .foregroundStyle(Color(red: 0.36, green: 0.86, blue: 0.6))
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.11, green: 0.23, blue: 0.18),
                                Color(red: 0.05, green: 0.12, blue: 0.08)
                            ],
                            center: UnitPoint(x: 0.5, y: -0.1),
                            startRadius: 0,
                            endRadius: 250
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .frame(width: 230)

            Text("onboarding.page3.title")
                .font(.system(size: 26, weight: .heavy))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)

            Text("onboarding.page3.desc")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .frame(maxWidth: 290)
        }
        .padding(.horizontal, 30)
    }

    // MARK: - Page 4: First Memo

    private var page4FirstMemo: some View {
        VStack(spacing: 24) {
            // Live preview card
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Theme.accent)
                        .frame(width: 5, height: 5)
                    Text("Vellure · \(String(localized: "type.plain"))")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundStyle(Theme.accent)
                }
                Text(firstMemoText.isEmpty ? String(localized: "onboarding.preview.placeholder") : firstMemoText)
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(firstMemoText.isEmpty ? .white.opacity(0.4) : .white)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, minHeight: 20, alignment: .leading)
                    .animation(.easeInOut(duration: 0.15), value: firstMemoText)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.11, green: 0.23, blue: 0.18),
                                Color(red: 0.05, green: 0.12, blue: 0.08)
                            ],
                            center: UnitPoint(x: 0.5, y: -0.1),
                            startRadius: 0,
                            endRadius: 250
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .frame(width: 230)

            Text("onboarding.page4.title")
                .font(.system(size: 26, weight: .heavy))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)

            Text("onboarding.page4.desc")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .frame(maxWidth: 290)

            // Input field
            HStack {
                TextField("onboarding.input.placeholder", text: $firstMemoText)
                    .font(.system(size: 15))
            }
            .padding(14)
            .background(Theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Theme.divider, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 12, y: 4)
            .padding(.horizontal, 6)
        }
        .padding(.horizontal, 30)
    }
}

// MARK: - Siri Voice Bar Animation

private struct SiriBar: View {
    let delay: Double
    @State private var animating = false

    var body: some View {
        Capsule()
            .fill(Color(red: 0.36, green: 0.86, blue: 0.6))
            .frame(width: 5, height: animating ? 26 : 9)
            .animation(
                .easeInOut(duration: 0.5).repeatForever(autoreverses: true).delay(delay),
                value: animating
            )
            .onAppear { animating = true }
    }
}
