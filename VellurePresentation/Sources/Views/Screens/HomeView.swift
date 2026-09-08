import SwiftUI
import UIKit
import SwiftData
import VellureCore
import VellureData

// swiftlint:disable:next type_body_length
public struct HomeView: View {
    /// 이 화면이 담당하는 표면. 탭마다 하나씩 띄운다.
    private let surface: Surface

    @Environment(MemoRepository.self) private var repository
    @Environment(\.scenePhase) private var scenePhase
    @State private var viewModel: MemoListViewModel?
    @State private var showNewMemo = false
    @State private var selectedMemo: Memo?
    @State private var showSettings = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var isReordering = false
    @State private var reorderHaptic = UISelectionFeedbackGenerator()
    @State private var draggingId: UUID?
    @State private var dragOffsetY: CGFloat = 0
    @State private var dropTargetIndex: Int?
    @State private var activeCardMidYs: [UUID: CGFloat] = [:]
    @State private var reorderMidYs: [UUID: CGFloat] = [:]
    @State private var dragBaseMidY: CGFloat = 0

    public init(surface: Surface) {
        self.surface = surface
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                if let viewModel, !viewModel.memos.isEmpty {
                    SearchFilterBar(
                        searchText: Binding(
                            get: { viewModel.searchText },
                            set: { viewModel.searchText = $0 }
                        ),
                        typeFilter: Binding(
                            get: { viewModel.typeFilter },
                            set: { viewModel.typeFilter = $0 }
                        ),
                        displayFilter: viewModel.usesDisplayState
                            ? Binding(
                                get: { viewModel.displayFilter },
                                set: { viewModel.displayFilter = $0 }
                            )
                            : nil,
                        types: viewModel.availableTypes
                    )
                    .padding(.bottom, 10)

                    if viewModel.isFiltering && viewModel.filteredMemos.isEmpty {
                        Spacer()
                        noResultsView(viewModel)
                        Spacer()
                    } else {
                        memoList(viewModel)
                    }
                } else {
                    Spacer()
                    EmptyStateView { showNewMemo = true }
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.background)
            .navigationBarHidden(true)
            .liveActivityErrorAlert(
                Binding(
                    get: { viewModel?.activityError },
                    set: { viewModel?.activityError = $0 }
                )
            )
            .sheet(isPresented: $showNewMemo) {
                MemoEditView(memo: nil)
                    .environment(repository)
                    .onDisappear { viewModel?.refresh() }
            }
            .sheet(item: $selectedMemo) { memo in
                MemoEditView(memo: memo)
                    .environment(repository)
                    .onDisappear { viewModel?.refresh() }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = MemoListViewModel(repository: repository, surface: surface)
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                viewModel?.refresh()
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(Date.now.formatted(.dateTime.month().day().weekday(.wide)))
                    .scaledFont(13, weight: .semibold)
                    .foregroundStyle(Theme.textSecondary)
                Text(LocalizedStringKey(surface == .memo ? "home.title" : "home.widget.title"))
                    .scaledFont(27, weight: .heavy)
                    .foregroundStyle(Theme.textPrimary)
            }

            Spacer(minLength: 12)

            HStack(spacing: 8) {
                if isReordering {
                    Button {
                        withAnimation { isReordering = false }
                    } label: {
                        Text("home.done")
                            .scaledFont(13, weight: .bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 7)
                            .background(Theme.accent)
                            .clipShape(Capsule())
                    }
                } else {
                    if viewModel?.memos.isEmpty == false {
                        Button {
                            reorderHaptic.prepare()
                            withAnimation { isReordering = true }
                        } label: {
                            Image(systemName: "arrow.up.arrow.down")
                                .scaledFont(14, weight: .bold)
                                .foregroundStyle(Theme.textSecondary)
                                .frame(width: 34, height: 34)
                                .background(Theme.chipBackground)
                                .clipShape(Circle())
                        }
                        .accessibilityLabel("a11y.header.reorder")
                    }

                    Button { showNewMemo = true } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .scaledFont(12, weight: .bold)
                            // 접근성 글자 크기에서는 라벨이 여러 줄로 접혀 버튼이 뭉개진다.
                            // 아이콘만 남긴다. VoiceOver는 접근성 레이블로 읽으므로 정보 손실이 없다.
                            if !dynamicTypeSize.isAccessibilitySize {
                                Text("home.new")
                                    .scaledFont(13, weight: .bold)
                                    .lineLimit(1)
                            }
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Theme.accent)
                        .clipShape(Capsule())
                    }
                    .accessibilityLabel("a11y.header.newMemo")

                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                            .scaledFont(15)
                            .foregroundStyle(Theme.textSecondary)
                            .frame(width: 34, height: 34)
                            .background(Theme.chipBackground)
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("a11y.header.settings")
                }
            }
        }
    }

    // MARK: - Memo List

    private func deleteMemo(_ memo: Memo, vm: MemoListViewModel) {
        if let activityId = memo.activityId {
            Task { await LiveActivityService.shared.end(activityId: activityId) }
        }
        vm.delete(memo)
    }

    @ViewBuilder
    private func memoContextMenu(for memo: Memo, vm: MemoListViewModel) -> some View {
        Button {
            vm.toggleActivity(for: memo)
        } label: {
            Label(
                memo.activityId != nil ? "context.stopActivity" : "context.startActivity",
                systemImage: memo.activityId != nil ? "stop.circle" : "play.circle"
            )
        }

        Button {
            selectedMemo = memo
        } label: {
            Label("context.edit", systemImage: "pencil")
        }

        Divider()

        Button(role: .destructive) {
            deleteMemo(memo, vm: vm)
        } label: {
            Label("context.delete", systemImage: "trash")
        }
    }

    @ViewBuilder
    private func memoList(_ vm: MemoListViewModel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // 검색·필터 중에는 섹션을 접고 결과만 한 목록으로 보여준다.
                // 부분 집합에서 드래그 정렬을 허용하면 sortOrder가 어긋난다.
                if vm.isFiltering {
                    resultSection(vm.filteredMemos, vm: vm)
                } else {
                    sectionedList(vm)
                }
            }
            .padding(.bottom, 20)
        }
        .scrollDisabled(draggingId != nil)
        .coordinateSpace(name: "reorder")
        .onPreferenceChange(CardMidYKey.self) { activeCardMidYs = $0 }
    }

    /// 검색·필터 결과 목록 (정렬 불가)
    private func resultSection(_ items: [Memo], vm: MemoListViewModel) -> some View {
        VStack(spacing: 8) {
            ForEach(items) { memo in
                MemoCardView(
                    memo: memo,
                    onTap: { selectedMemo = memo },
                    onToggleActivity: { vm.toggleActivity(for: memo) },
                    onDelete: { deleteMemo(memo, vm: vm) },
                    isActive: vm.isActive(memo)
                )
                .frame(maxWidth: .infinity)
                .contextMenu { memoContextMenu(for: memo, vm: vm) }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.top, 6)
    }

    @ViewBuilder
    private func sectionedList(_ vm: MemoListViewModel) -> some View {
        Group {
            // 표시 상태를 쓰는 표면(메모 탭)만 "잠금화면 표시 중" 그룹을 앞세운다.
            // 위젯 탭은 앱이 켜고 끄는 개념이 없어 타입별 그룹만 남는다.
            if vm.usesDisplayState {
                let active = vm.activeMemos
                if !active.isEmpty {
                    activeSectionHeader(count: active.count)
                    reorderableSection(active, matches: { $0.activityId != nil }, vm: vm)
                }
            }

            ForEach(vm.availableTypes, id: \.self) { type in
                let group = vm.usesDisplayState
                    ? vm.inactiveMemos(ofType: type)
                    : vm.memos.filter { $0.renderType == type }
                if !group.isEmpty {
                    sectionHeader(type, count: group.count)
                    reorderableSection(
                        group,
                        matches: {
                            $0.renderType == type
                                && (!vm.usesDisplayState || $0.activityId == nil)
                        },
                        vm: vm
                    )
                }
            }
        }
    }

    /// 검색·필터 결과가 없을 때
    private func noResultsView(_ vm: MemoListViewModel) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .scaledFont(30, weight: .light)
                .foregroundStyle(Theme.textSecondary)
                .accessibilityHidden(true)
            Text("search.empty.title")
                .scaledFont(15, weight: .bold)
                .foregroundStyle(Theme.textPrimary)
            Button {
                vm.clearFilters()
            } label: {
                Text("search.empty.reset")
                    .scaledFont(13, weight: .semibold)
                    .foregroundStyle(Theme.accent)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
    }

    // MARK: - Reorderable Section (custom drag)

    @ViewBuilder
    private func reorderableSection(
        _ items: [Memo],
        matches: @escaping (Memo) -> Bool,
        vm: MemoListViewModel
    ) -> some View {
        VStack(spacing: 8) {
            ForEach(items) { memo in
                HStack(spacing: 4) {
                    if isReordering {
                        Image(systemName: "line.3.horizontal")
                            .scaledFont(16, weight: .semibold)
                            .foregroundStyle(Theme.textSecondary)
                            .frame(width: 24, height: 44)
                            .contentShape(Rectangle())
                            .accessibilityLabel("a11y.reorder.handle")
                            .highPriorityGesture(reorderGesture(memo: memo, items: items, matches: matches, vm: vm))
                    }

                    MemoCardView(
                        memo: memo,
                        onTap: { selectedMemo = memo },
                        onToggleActivity: { vm.toggleActivity(for: memo) },
                        onDelete: { deleteMemo(memo, vm: vm) },
                        isActive: vm.isActive(memo)
                    )
                    // 정렬 모드에서 드래그 핸들이 붙어도 행 전체 폭이 늘지 않도록
                    // 카드가 남은 폭을 받아 줄어들게 한다.
                    .frame(maxWidth: .infinity)
                    .contextMenu { memoContextMenu(for: memo, vm: vm) }
                }
                .frame(maxWidth: .infinity)
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: CardMidYKey.self,
                            value: draggingId != nil
                                ? [:]
                                : [memo.id: geo.frame(in: .named("reorder")).midY]
                        )
                    }
                )
                .offset(y: draggingId == memo.id ? dragOffsetY : 0)
                .zIndex(draggingId == memo.id ? 1 : 0)
                .shadow(color: draggingId == memo.id ? .black.opacity(0.18) : .clear, radius: 8, y: 4)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
        .padding(.bottom, 8)
        .animation(.snappy(duration: 0.22), value: draggingId)
    }

    private func reorderGesture(
        memo: Memo,
        items: [Memo],
        matches: @escaping (Memo) -> Bool,
        vm: MemoListViewModel
    ) -> some Gesture {
        DragGesture(minimumDistance: 2, coordinateSpace: .named("reorder"))
            .onChanged { value in
                if draggingId != memo.id {
                    draggingId = memo.id
                    reorderMidYs = activeCardMidYs
                    dragBaseMidY = activeCardMidYs[memo.id] ?? value.startLocation.y
                    dropTargetIndex = items.firstIndex { $0.id == memo.id }
                    reorderHaptic.prepare()
                }
                dragOffsetY = value.translation.height
                let centerY = dragBaseMidY + dragOffsetY
                let newIndex = items
                    .filter { $0.id != memo.id && (reorderMidYs[$0.id] ?? 0) < centerY }
                    .count
                if newIndex != dropTargetIndex {
                    dropTargetIndex = newIndex
                    reorderHaptic.selectionChanged()
                    reorderHaptic.prepare()
                }
            }
            .onEnded { _ in
                if let from = items.firstIndex(where: { $0.id == memo.id }),
                   let target = dropTargetIndex, from != target {
                    vm.moveInGroup(items, fromIndex: from, toIndex: target, matches: matches)
                    vm.commitReorder()
                }
                draggingId = nil
                dragOffsetY = 0
                dropTargetIndex = nil
            }
    }

    private func activeSectionHeader(count: Int) -> some View {
        HStack(spacing: 5) {
            Image(systemName: "lock.fill")
                .scaledFont(11, weight: .semibold)
            Text("home.section.active")
                .scaledFont(13, weight: .bold)
            Text("\(count)")
                .scaledFont(12, weight: .semibold)
        }
        .foregroundStyle(Theme.accent)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 2)
    }

    private func sectionHeader(_ type: RenderType, count: Int) -> some View {
        HStack(spacing: 5) {
            Image(systemName: typeIconName(type))
                .scaledFont(11, weight: .semibold)
            Text(typeDisplayName(type))
                .scaledFont(13, weight: .bold)
            Text("\(count)")
                .scaledFont(12, weight: .semibold)
        }
        .foregroundStyle(Theme.textSecondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 2)
    }

    private func typeIconName(_ type: RenderType) -> String {
        switch type {
        case .plain: "note.text"
        case .checklist: "checklist"
        case .dday: "calendar"
        case .countdown: "timer"
        case .progress: "chart.bar.fill"
        }
    }

    private func typeDisplayName(_ type: RenderType) -> String {
        switch type {
        case .plain: String(localized: "type.plain")
        case .checklist: String(localized: "type.checklist")
        case .dday: String(localized: "type.dday")
        case .countdown: String(localized: "type.countdown")
        case .progress: String(localized: "type.progress")
        }
    }
}

private struct CardMidYKey: PreferenceKey {
    static let defaultValue: [UUID: CGFloat] = [:]
    static func reduce(value: inout [UUID: CGFloat], nextValue: () -> [UUID: CGFloat]) {
        value.merge(nextValue()) { _, new in new }
    }
}

#if DEBUG
#Preview("메모 탭") {
    if let preview = PreviewSupport.makeRepository() {
        HomeView(surface: .memo)
            .environment(preview.repository)
            .modelContainer(preview.container)
    }
}

#Preview("위젯 탭") {
    if let preview = PreviewSupport.makeRepository() {
        HomeView(surface: .widget)
            .environment(preview.repository)
            .modelContainer(preview.container)
    }
}

#Preview("빈 상태") {
    if let preview = PreviewSupport.makeRepository(seeded: false) {
        HomeView(surface: .memo)
            .environment(preview.repository)
            .modelContainer(preview.container)
    }
}
#endif
