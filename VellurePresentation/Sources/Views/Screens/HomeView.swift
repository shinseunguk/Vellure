import SwiftUI
import SwiftData
import VellureCore
import VellureData

public struct HomeView: View {
    @Environment(MemoRepository.self) private var repository
    @Environment(\.scenePhase) private var scenePhase
    @State private var viewModel: MemoListViewModel?
    @State private var showNewMemo = false
    @State private var selectedMemo: Memo?
    @State private var showSettings = false
    @State private var isEditing = false

    public init() {}

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                if let viewModel, !viewModel.memos.isEmpty {
                    memoList(viewModel)
                } else {
                    Spacer()
                    EmptyStateView { showNewMemo = true }
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.background)
            .navigationBarHidden(true)
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
                viewModel = MemoListViewModel(repository: repository)
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
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
                Text("home.title")
                    .font(.system(size: 27, weight: .heavy))
                    .foregroundStyle(Theme.textPrimary)
            }

            Spacer(minLength: 12)

            HStack(spacing: 8) {
                if viewModel?.memos.isEmpty == false {
                    Button {
                        withAnimation { isEditing.toggle() }
                    } label: {
                        Text(isEditing ? "home.done" : "home.edit")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(isEditing ? .white : Theme.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(isEditing ? Theme.accent : Theme.chipBackground)
                            .clipShape(Capsule())
                    }
                }

                if !isEditing {
                    Button { showNewMemo = true } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .bold))
                            Text("home.new")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Theme.accent)
                        .clipShape(Capsule())
                    }

                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 15))
                            .foregroundStyle(Theme.textSecondary)
                            .frame(width: 34, height: 34)
                            .background(Theme.chipBackground)
                            .clipShape(Circle())
                    }
                }
            }
            .fixedSize()
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
        List {
            ForEach(RenderType.allCases, id: \.self) { type in
                let group = vm.memos(ofType: type)
                if !group.isEmpty {
                    Section {
                        ForEach(group) { memo in
                            MemoCardView(
                                memo: memo,
                                onTap: { selectedMemo = memo },
                                onToggleActivity: { vm.toggleActivity(for: memo) },
                                onDelete: { deleteMemo(memo, vm: vm) }
                            )
                            .contextMenu { memoContextMenu(for: memo, vm: vm) }
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 13, leading: 20, bottom: 4, trailing: 20))
                        }
                        .onDelete { offsets in vm.delete(type: type, at: offsets) }
                        .onMove { source, destination in vm.reorder(type: type, from: source, to: destination) }
                    } header: {
                        sectionHeader(type, count: group.count)
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .environment(\.editMode, .constant(isEditing ? .active : .inactive))
    }

    private func sectionHeader(_ type: RenderType, count: Int) -> some View {
        HStack(spacing: 5) {
            Image(systemName: typeIconName(type))
                .font(.system(size: 11, weight: .semibold))
            Text(typeDisplayName(type))
                .font(.system(size: 13, weight: .bold))
            Text("\(count)")
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundStyle(Theme.textSecondary)
        .textCase(nil)
        .listRowInsets(EdgeInsets(top: 14, leading: 20, bottom: 2, trailing: 20))
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

#if DEBUG
#Preview("메모 목록") {
    if let preview = PreviewSupport.makeRepository() {
        HomeView()
            .environment(preview.repository)
            .modelContainer(preview.container)
    }
}

#Preview("빈 상태") {
    if let preview = PreviewSupport.makeRepository(seeded: false) {
        HomeView()
            .environment(preview.repository)
            .modelContainer(preview.container)
    }
}
#endif
