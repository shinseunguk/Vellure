import SwiftUI
import UIKit
import VellureCore

/// 드래그로 순서를 바꿀 수 있는 메모 그룹.
///
/// 드래그 상태를 그룹 안에 둔다. 정렬은 그룹 단위(`moveInGroup`)로만 일어나므로
/// 상태를 화면 전체에 두면 어느 그룹의 드래그인지 계속 가려내야 한다.
struct MemoReorderableSection: View {
    /// 카드 사이 간격
    private static let cardSpacing: CGFloat = 8
    /// 드래그 핸들 크기
    private static let handleSize: CGSize = CGSize(width: 24, height: 44)

    let items: [Memo]
    let matches: (Memo) -> Bool
    let viewModel: MemoListViewModel
    let isReordering: Bool
    /// 스크롤 전체에서 모은 카드 중심 y. 드롭 위치를 판정하는 기준이다.
    let cardMidYs: [UUID: CGFloat]
    let onSelect: (Memo) -> Void
    let onDelete: (Memo) -> Void
    let contextMenu: (Memo) -> AnyView

    @State private var draggingId: UUID?
    @State private var dragOffsetY: CGFloat = 0
    @State private var dropTargetIndex: Int?
    /// 드래그 시작 시점의 카드 위치 스냅샷.
    /// 드래그 중에도 실시간 값을 쓰면 카드가 움직일 때마다 기준이 흔들린다.
    @State private var frozenMidYs: [UUID: CGFloat] = [:]
    @State private var dragBaseMidY: CGFloat = 0
    @State private var haptic = UISelectionFeedbackGenerator()

    var body: some View {
        VStack(spacing: Self.cardSpacing) {
            ForEach(items) { memo in
                row(memo)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
        .padding(.bottom, 8)
        .animation(.snappy(duration: 0.22), value: draggingId)
    }

    private func row(_ memo: Memo) -> some View {
        HStack(spacing: 4) {
            if isReordering {
                handle(memo)
            }

            MemoCardView(
                memo: memo,
                onTap: { onSelect(memo) },
                onToggleActivity: { viewModel.toggleActivity(for: memo) },
                onDelete: { onDelete(memo) },
                isActive: viewModel.isActive(memo),
                allowsPublishing: viewModel.usesDisplayState
            )
            // 정렬 모드에서 드래그 핸들이 붙어도 행 전체 폭이 늘지 않도록
            // 카드가 남은 폭을 받아 줄어들게 한다.
            .frame(maxWidth: .infinity)
            .contextMenu { contextMenu(memo) }
        }
        .frame(maxWidth: .infinity)
        .background(midYReporter(memo))
        .offset(y: draggingId == memo.id ? dragOffsetY : 0)
        .zIndex(draggingId == memo.id ? 1 : 0)
        .shadow(color: draggingId == memo.id ? .black.opacity(0.18) : .clear, radius: 8, y: 4)
    }

    private func handle(_ memo: Memo) -> some View {
        Image(systemName: "line.3.horizontal")
            .scaledFont(16, weight: .semibold)
            .foregroundStyle(Theme.textSecondary)
            .frame(width: Self.handleSize.width, height: Self.handleSize.height)
            .contentShape(Rectangle())
            .accessibilityLabel("a11y.reorder.handle")
            .highPriorityGesture(gesture(for: memo))
    }

    /// 카드 중심 y를 위로 올려보낸다. 드래그 중에는 보내지 않는다 —
    /// 움직이는 카드의 위치가 섞이면 드롭 위치가 튄다.
    private func midYReporter(_ memo: Memo) -> some View {
        GeometryReader { geo in
            Color.clear.preference(
                key: CardMidYKey.self,
                value: draggingId != nil
                    ? [:]
                    : [memo.id: geo.frame(in: .named("reorder")).midY]
            )
        }
    }

    private func gesture(for memo: Memo) -> some Gesture {
        DragGesture(minimumDistance: 2, coordinateSpace: .named("reorder"))
            .onChanged { value in
                if draggingId != memo.id {
                    draggingId = memo.id
                    frozenMidYs = cardMidYs
                    dragBaseMidY = cardMidYs[memo.id] ?? value.startLocation.y
                    dropTargetIndex = items.firstIndex { $0.id == memo.id }
                    haptic.prepare()
                }
                dragOffsetY = value.translation.height

                let centerY = dragBaseMidY + dragOffsetY
                let newIndex = items
                    .filter { $0.id != memo.id && (frozenMidYs[$0.id] ?? 0) < centerY }
                    .count
                if newIndex != dropTargetIndex {
                    dropTargetIndex = newIndex
                    haptic.selectionChanged()
                    haptic.prepare()
                }
            }
            .onEnded { _ in
                if let from = items.firstIndex(where: { $0.id == memo.id }),
                   let target = dropTargetIndex, from != target {
                    viewModel.moveInGroup(items, fromIndex: from, toIndex: target, matches: matches)
                    viewModel.commitReorder()
                }
                draggingId = nil
                dragOffsetY = 0
                dropTargetIndex = nil
            }
    }
}

/// 스크롤 안의 카드 중심 y를 모아 올린다.
struct CardMidYKey: PreferenceKey {
    static let defaultValue: [UUID: CGFloat] = [:]

    static func reduce(value: inout [UUID: CGFloat], nextValue: () -> [UUID: CGFloat]) {
        value.merge(nextValue()) { _, new in new }
    }
}
