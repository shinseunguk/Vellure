import SwiftUI
import UIKit
import SwiftData
import VellureCore
import VellureData

public struct HomeView: View {
    /// 이 화면이 담당하는 표면. 탭마다 하나씩 띄운다.
    private let surface: Surface

    @Environment(MemoRepository.self) private var repository
    @Environment(\.scenePhase) private var scenePhase
    @State private var viewModel: MemoListViewModel?
    @State private var showNewMemo = false
    @State private var selectedMemo: Memo?
    @State private var showSettings = false
    @State private var showWidgetGuide = false
    /// 위젯 안내를 한 번이라도 본 적 있는지. 매번 띄우면 성가시다.
    @AppStorage("hasSeenWidgetGuide") private var hasSeenWidgetGuide = false
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
                    EmptyStateView(surface: surface) { showNewMemo = true }
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
                MemoEditView(memo: nil, surface: surface)
                    .environment(repository)
                    .onDisappear {
                        viewModel?.refresh()
                        presentWidgetGuideIfNeeded()
                    }
            }
            .sheet(isPresented: $showWidgetGuide) {
                WidgetGuideView()
            }
            .sheet(item: $selectedMemo) { memo in
                MemoEditView(memo: memo, surface: surface)
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

    /// 위젯 메모를 처음 만든 직후 한 번만 배치 방법을 알린다.
    /// 앱이 위젯을 대신 설치할 수 없어, 안내가 없으면 "위젯이 안 나온다"로 끝난다.
    private func presentWidgetGuideIfNeeded() {
        guard surface == .widget, !hasSeenWidgetGuide else { return }
        guard viewModel?.memos.isEmpty == false else { return }
        hasSeenWidgetGuide = true
        showWidgetGuide = true
    }

    // MARK: - Header

    private var header: some View {
        MemoListHeader(
            surface: surface,
            canReorder: viewModel?.memos.isEmpty == false,
            isReordering: $isReordering,
            onNewMemo: { showNewMemo = true },
            onSettings: { showSettings = true }
        )
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
        // 위젯 탭에서는 새로 올리지 않는다. 이미 떠 있는 것만 내릴 수 있다.
        if vm.usesDisplayState || vm.isActive(memo) {
            Button {
                vm.toggleActivity(for: memo)
            } label: {
                Label(
                    memo.activityId != nil ? "context.stopActivity" : "context.startActivity",
                    systemImage: memo.activityId != nil ? "stop.circle" : "play.circle"
                )
            }
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

                if surface == .widget && !vm.isFiltering {
                    widgetGuideEntry
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
                    isActive: vm.isActive(memo),
                    allowsPublishing: vm.usesDisplayState
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
                    MemoSectionHeader(kind: .active, count: active.count)
                    reorderSection(active, matches: { $0.activityId != nil }, vm: vm)
                }
            }

            ForEach(vm.availableTypes, id: \.self) { type in
                let group = vm.usesDisplayState
                    ? vm.inactiveMemos(ofType: type)
                    : vm.memos.filter { $0.renderType == type }
                if !group.isEmpty {
                    MemoSectionHeader(kind: .type(type), count: group.count)
                    reorderSection(
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

    /// 드래그 정렬이 가능한 한 그룹.
    private func reorderSection(
        _ items: [Memo],
        matches: @escaping (Memo) -> Bool,
        vm: MemoListViewModel
    ) -> some View {
        MemoReorderableSection(
            items: items,
            matches: matches,
            viewModel: vm,
            isReordering: isReordering,
            cardMidYs: activeCardMidYs,
            onSelect: { selectedMemo = $0 },
            onDelete: { deleteMemo($0, vm: vm) },
            contextMenu: { memo in AnyView(memoContextMenu(for: memo, vm: vm)) }
        )
    }

    /// 위젯 배치 방법으로 가는 입구.
    /// 메모를 만들어도 위젯을 놓지 않으면 아무 데도 보이지 않으므로 목록 안에 상시 둔다.
    private var widgetGuideEntry: some View {
        Button {
            showWidgetGuide = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "questionmark.circle")
                    .scaledFont(13, weight: .semibold)
                Text("guide.entry")
                    .scaledFont(13, weight: .semibold)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .scaledFont(11, weight: .semibold)
            }
            .foregroundStyle(Theme.textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Theme.chipBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
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
