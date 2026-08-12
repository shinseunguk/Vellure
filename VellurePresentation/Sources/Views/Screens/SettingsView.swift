import StoreKit
import SwiftUI
import UIKit
import VellureCore
import VellureData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.requestReview) private var requestReview
    @AppStorage("appearanceMode") private var appearanceMode: String = AppearanceMode.system.rawValue

    private let activitySupported = LiveActivityService.shared.isSupported

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    diagnosticsSection
                    siriSection
                    automationSection
                    themeSection
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
        }
    }

    // MARK: - Diagnostics

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
                            .font(.system(size: 13.5, weight: .bold))
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
                            .font(.system(size: 14))
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
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.leading, 4)
            }
        }
    }

    private func diagRow(label: String, isOn: Bool) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            Text(isOn
                ? String(localized: "settings.activity.available")
                : String(localized: "settings.activity.disabled"))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isOn ? Theme.accent : .red)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
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
                    .font(.system(size: 14, weight: .bold))
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
                                .font(.system(size: 14, weight: .semibold))
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
                    .font(.system(size: 11.5))
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
                .font(.system(size: 13))
                .foregroundStyle(Theme.accent)
                .frame(width: 30, height: 30)
                .background(Theme.accent.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(desc)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary)
                    .lineSpacing(2)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Theme

    private var themeSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("settings.appearance")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Picker("", selection: $appearanceMode) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Text(mode.displayName).tag(mode.rawValue)
                    }
                }
                .pickerStyle(.menu)
                .tint(Theme.accent)
            }
            .padding(15)
        }
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Theme.divider, lineWidth: 1)
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
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    HStack(spacing: 7) {
                        Text("settings.feedback.dest")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.textSecondary)
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 10, weight: .semibold))
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
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
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
            .font(.system(size: 12))
            .foregroundStyle(Theme.textSecondary)
            .padding(.top, 6)
    }

    // MARK: - Helper

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(Theme.textSecondary)
            .padding(.leading, 4)
    }
}

#if DEBUG
#Preview {
    SettingsView()
}
#endif
