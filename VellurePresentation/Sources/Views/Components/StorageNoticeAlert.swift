import SwiftUI
import VellureCore

/// 저장소를 열지 못해 메모리 컨테이너로 폴백했을 때 알리는 알럿.
/// 이 상태에서는 이번 실행에서 만든 내용이 저장되지 않으므로 반드시 알려야 한다.
private struct StorageNoticeAlert: ViewModifier {
    @State private var isPresented = AppModelContainer.status.needsUserNotice

    func body(content: Content) -> some View {
        content.alert("storage.error.title", isPresented: $isPresented) {
            Button("common.close", role: .cancel) {}
        } message: {
            Text("storage.error.message")
        }
    }
}

extension View {
    /// 저장소 폴백 상황을 사용자에게 알린다. 앱 타깃에서 호출한다.
    public func storageNoticeAlert() -> some View {
        modifier(StorageNoticeAlert())
    }
}
