import SwiftUI
import UIKit
import VellureCore

/// Live Activity를 띄우지 못했을 때 이유를 알리는 알럿.
/// 설정을 켜야 하는 경우에는 설정 앱으로 바로 갈 수 있게 한다.
private struct LiveActivityErrorAlert: ViewModifier {
    @Binding var error: LiveActivityError?

    func body(content: Content) -> some View {
        content.alert(
            "liveActivity.error.title",
            isPresented: isPresented,
            presenting: error
        ) { error in
            if error == .notEnabled,
               let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                Button("liveActivity.error.openSettings") {
                    UIApplication.shared.open(settingsURL)
                }
            }
            Button("common.close", role: .cancel) {}
        } message: { error in
            Text(messageKey(for: error))
        }
    }

    private var isPresented: Binding<Bool> {
        Binding(
            get: { error != nil },
            set: { if !$0 { error = nil } }
        )
    }

    private func messageKey(for error: LiveActivityError) -> LocalizedStringKey {
        switch error {
        case .notEnabled: "liveActivity.error.notEnabled"
        case .tooManyActivities: "liveActivity.error.tooMany"
        case .contentTooLarge: "liveActivity.error.tooLarge"
        case .unknown: "liveActivity.error.unknown"
        }
    }
}

extension View {
    /// Live Activity 시작 실패를 알럿으로 안내한다.
    func liveActivityErrorAlert(_ error: Binding<LiveActivityError?>) -> some View {
        modifier(LiveActivityErrorAlert(error: error))
    }
}
