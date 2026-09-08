import SwiftUI
import VellureCore

/// 목록 안에서 그룹의 시작을 알리는 머리글.
/// 잠금화면에 떠 있는 그룹은 강조색으로, 타입별 그룹은 보조색으로 구분한다.
struct MemoSectionHeader: View {
    enum Kind {
        /// 잠금화면에 표시 중인 메모 그룹
        case active
        /// 타입별 그룹
        case type(RenderType)
    }

    let kind: Kind
    let count: Int

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: iconName)
                .scaledFont(11, weight: .semibold)
            title
                .scaledFont(13, weight: .bold)
            Text("\(count)")
                .scaledFont(12, weight: .semibold)
        }
        .foregroundStyle(tint)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 2)
    }

    @ViewBuilder
    private var title: some View {
        switch kind {
        case .active: Text("home.section.active")
        case .type(let type): Text(type.displayName)
        }
    }

    private var iconName: String {
        switch kind {
        case .active: "lock.fill"
        case .type(let type): type.iconName
        }
    }

    private var tint: Color {
        switch kind {
        case .active: Theme.accent
        case .type: Theme.textSecondary
        }
    }
}
