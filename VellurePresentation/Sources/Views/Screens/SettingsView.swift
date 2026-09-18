import StoreKit
import SwiftUI
import UIKit
import VellureCore
import VellureData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.requestReview) private var requestReview
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("appearanceMode") private var appearanceMode: String = AppearanceMode.system.rawValue
    /// 확장과 함께 읽어야 해서 App Group 저장소를 쓴다.
    @AppStorage(TextScale.storageKey, store: TextScale.sharedDefaults)
    private var textScale: Double = Double(TextScale.default)
    @Environment(MemoRepository.self) private var repository

    @State private var activitySupported = LiveActivityService.shared.isSupported
    /// 화면을 열 때 한 번만 읽는다. 이력은 이 화면에 머무는 동안 바뀌지 않는다.
    @State private var history: [ActivityRecord] = ActivityHistory.recent()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    diagnosticsSection
                    historySection
                    siriSection
                    automationSection
                    themeSection
                    textScaleSection
                    miscSection
                    versionLabel
                }
                .padding(20)
            }
            .background(Theme.background)
            .navigationTitle(String(localized: "settings.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("settings.done") { dismiss() }
                }
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    activitySupported = LiveActivityService.shared.isSupported
                }
            }
        }
    }

    // MARK: - Diagnostics

    /// 최근 게시 이력. 섹션 구성은 컴포넌트가 들고 있다.
    @ViewBuilder
    private var historySection: some View {
        if !history.isEmpty {
            ActivityHistoryView(records: history)
        }
    }

    private var diagnosticsSection: some View {
        VStack(alignment: .leading, spacing: 9) {
            sectionLabel(String(localized: "settings.section.diagnostics"))
            VStack(spacing: 0) {
                // Status banner
                HStack {
                    HStack(spacing: 10) {
                        Circle()
                            .fill(activitySupported ? Theme.accent : .orange)
                            .frame(width: 9, height: 9)
                        Text(activitySupported
                            ? String(localized: "settings.diag.ready")
                            : String(localized: "settings.diag.warn"))
                            .scaledFont(13.5, weight: .bold)
                            .foregroundStyle(activitySupported ? Theme.accent : .orange)
                    }
                    Spacer()
                }
                .padding(15)
                .background(activitySupported
                    ? Theme.accent.opacity(0.1)
                    : Color.orange.opacity(0.1))

                Divider()

                // Live Activity toggle row → 시스템 설정 딥링크
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                } label: {
                    diagRow(
                        label: String(localized: "settings.diag.liveActivity"),
                        isOn: activitySupported
                    )
                }
                .buttonStyle(.plain)

                Divider().padding(.leading, 16)

                // End all button
                Button {
                    Task { await LiveActivityService.shared.endAll() }
                } label: {
                    HStack {
                        Text("settings.activity.endAll")
                            .scaledFont(14)
                            .foregroundStyle(.red)
                        Spacer()
                    }
                    .padding(15)
                }
            }
            .background(Theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Theme.divider, lineWidth: 1)
            )

            if !activitySupported {
                Text("settings.diag.hint")
                    .scaledFont(12)
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.leading, 4)
            }
        }
    }

    private func diagRow(label: String, isOn: Bool) -> some View {
        HStack {
            Text(label)
                .scaledFont(14)
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            Text(isOn
                ? String(localized: "settings.activity.available")
                : String(localized: "settings.activity.disabled"))
                .scaledFont(13, weight: .semibold)
                .foregroundStyle(isOn ? Theme.accent : .red)
            Image(systemName: "chevron.right")
                .scaledFont(12, weight: .semibold)
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(15)
        .contentShape(Rectangle())
    }

    // MARK: - Siri

    private var siriSection: some View {
        VStack(alignment: .leading, spacing: 9) {
            sectionLabel(String(localized: "settings.section.siri"))
            VStack(alignment: .leading, spacing: 0) {
                Text("settings.siri.phrases")
                    .scaledFont(14, weight: .bold)
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 10)

                ForEach(siriPhrases, id: \.self) { phrase in
                    VStack(spacing: 0) {
                        Divider()
                        HStack(spacing: 10) {
                            Circle()
                                .fill(Theme.accent)
                                .frame(width: 7, height: 7)
                            Text("\"\(phrase)\"")
                                .scaledFont(14, weight: .semibold)
                                .foregroundStyle(Theme.textSecondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 9)
                    }
                }
            }
            .background(Theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Theme.divider, lineWidth: 1)
            )
        }
    }

    private var siriPhrases: [String] {
        [
            String(localized: "settings.siri.phrase1"),
            String(localized: "settings.siri.phrase2"),
            String(localized: "settings.siri.phrase3")
        ]
    }

    // MARK: - Automation

    private var automationSection: some View {
        VStack(alignment: .leading, spacing: 9) {
            sectionLabel(String(localized: "settings.section.automation"))
            VStack(spacing: 0) {
                autoRow(
                    icon: "house.fill",
                    title: String(localized: "settings.auto.home.title"),
                    desc: String(localized: "settings.auto.home.desc")
                )
                Divider().padding(.leading, 57)
                autoRow(
                    icon: "moon.fill",
                    title: String(localized: "settings.auto.night.title"),
                    desc: String(localized: "settings.auto.night.desc")
                )
                Divider().padding(.leading, 57)
                autoRow(
                    icon: "mappin",
                    title: String(localized: "settings.auto.location.title"),
                    desc: String(localized: "settings.auto.location.desc")
                )
                Divider()
                Text("settings.auto.note")
                    .scaledFont(11.5)
                    .foregroundStyle(Theme.textSecondary)
                    .padding(16)
                    .lineSpacing(3)
            }
            .background(Theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Theme.divider, lineWidth: 1)
            )
        }
    }

    private func autoRow(icon: String, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: icon)
                .scaledFont(13)
                .foregroundStyle(Theme.accent)
                .frame(width: 30, height: 30)
                .background(Theme.accent.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .scaledFont(13.5, weight: .semibold)
                    .foregroundStyle(Theme.textPrimary)
                Text(desc)
                    .scaledFont(12)
                    .foregroundStyle(Theme.textSecondary)
                    .lineSpacing(2)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Theme

    /// 잠금화면 글자 크기.
    /// 앱 화면은 Dynamic Type을 따르지만 Live Activity는 고정 크기로 그려
    /// 시스템 설정이 닿지 않는다. 그래서 따로 고르게 한다.
    private var textScaleSection: some View {
        TextScaleRow(scale: $textScale)
            .onChange(of: textScale) { _, newValue in
                // 확장은 App Group을 통해서만 설정을 볼 수 있다.
                TextScale.save(CGFloat(newValue))
                Task { await LiveActivityService.shared.refreshAll(repository: repository) }
            }
    }

    private var themeSection: some View {
        SettingsPickerRow(
            title: String(localized: "settings.appearance"),
            options: AppearanceMode.allCases,
            optionLabel: \.displayName,
            optionTag: \.rawValue,
            selection: $appearanceMode
        )
    }

    // MARK: - Misc

    private var miscSection: some View {
        VStack(spacing: 0) {
            Button {
                requestReview()
            } label: {
                HStack {
                    Text("settings.feedback")
                        .scaledFont(14)
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    HStack(spacing: 7) {
                        Text("settings.feedback.dest")
                            .scaledFont(12, weight: .semibold)
                            .foregroundStyle(Theme.textSecondary)
                        Image(systemName: "arrow.up.right")
                            .scaledFont(10, weight: .semibold)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                .padding(15)
            }

            Divider()

            NavigationLink {
                TermsView()
            } label: {
                HStack {
                    Text("settings.terms")
                        .scaledFont(14)
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .scaledFont(12, weight: .semibold)
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(15)
            }
        }
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Theme.divider, lineWidth: 1)
        )
    }

    // MARK: - Version

    private var versionLabel: some View {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return Text("Vellure v\(version) · \(String(localized: "settings.priceFree"))")
            .scaledFont(12)
            .foregroundStyle(Theme.textSecondary)
            .padding(.top, 6)
    }

    // MARK: - Helper

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .scaledFont(12, weight: .bold)
            .foregroundStyle(Theme.textSecondary)
            .padding(.leading, 4)
    }
}

#if DEBUG
#Preview {
    SettingsView()
}
#endif
