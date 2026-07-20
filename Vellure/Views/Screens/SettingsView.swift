import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    private let activitySupported = LiveActivityService.shared.isSupported
    private let appVersion: String = {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }()

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Live Activity 상태
                Section {
                    HStack {
                        Label("Live Activity", systemImage: "square.stack.3d.up")
                        Spacer()
                        Text(activitySupported ? "사용 가능" : "비활성")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(activitySupported ? Theme.accent : .red)
                    }

                    if !activitySupported {
                        Label {
                            Text("설정 → Vellure → Live Activity를 켜주세요")
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
                        Label("모든 Live Activity 종료", systemImage: "stop.circle")
                            .foregroundStyle(.red)
                    }
                } header: {
                    Text("잠금화면")
                }

                // MARK: - 앱 정보
                Section {
                    HStack {
                        Text("버전")
                        Spacer()
                        Text(appVersion)
                            .foregroundStyle(Theme.textSecondary)
                    }

                    HStack {
                        Text("최소 지원")
                        Spacer()
                        Text("iOS 17.0")
                            .foregroundStyle(Theme.textSecondary)
                    }
                } header: {
                    Text("앱 정보")
                }
            }
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("완료") { dismiss() }
                }
            }
        }
    }
}
