import SwiftUI
import VellureCore
import VellureData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appearanceMode") private var appearanceMode: String = AppearanceMode.system.rawValue

    private let activitySupported = LiveActivityService.shared.isSupported
    private let appVersion: String = {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Label("Live Activity", systemImage: "square.stack.3d.up")
                        Spacer()
                        Text(activitySupported
                            ? String(localized: "settings.activity.available")
                            : String(localized: "settings.activity.disabled"))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(activitySupported ? Theme.accent : .red)
                    }

                    if !activitySupported {
                        Label {
                            Text("settings.activity.guide")
                                .font(.system(size: 13))
                                .foregroundStyle(Theme.textSecondary)
                        } icon: {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundStyle(.orange)
                        }
                    }

                    Button {
                        Task { await LiveActivityService.shared.endAll() }
                    } label: {
                        Label("settings.activity.endAll", systemImage: "stop.circle")
                            .foregroundStyle(.red)
                    }
                } header: {
                    Text("settings.section.lockscreen")
                }

                Section {
                    Picker(selection: $appearanceMode) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Text(mode.displayName).tag(mode.rawValue)
                        }
                    } label: {
                        Label("settings.appearance", systemImage: "circle.lefthalf.filled")
                    }
                } header: {
                    Text("settings.section.display")
                }

                Section {
                    HStack {
                        Text("settings.version")
                        Spacer()
                        Text(appVersion)
                            .foregroundStyle(Theme.textSecondary)
                    }

                    HStack {
                        Text("settings.minOS")
                        Spacer()
                        Text("iOS 17.0")
                            .foregroundStyle(Theme.textSecondary)
                    }
                } header: {
                    Text("settings.section.appInfo")
                }
            }
            .navigationTitle(String(localized: "settings.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("settings.done") { dismiss() }
                }
            }
        }
    }
}
