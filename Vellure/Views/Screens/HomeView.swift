import SwiftUI

struct HomeView: View {
    @Environment(MemoRepository.self) private var repository
    @State private var viewModel: MemoListViewModel?
    @State private var showNewMemo = false
    @State private var selectedMemo: Memo?
    @State private var showSettings = false
    @State private var isEditing = false

    var body: some View {
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

    @ViewBuilder
    private func memoList(_ vm: MemoListViewModel) -> some View {
        List {
            ForEach(vm.memos) { memo in
                MemoCardView(
                    memo: memo,
                    onTap: { selectedMemo = memo },
                    onToggleActivity: { vm.toggleActivity(for: memo) }
                )
                .contextMenu {
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
                        if let activityId = memo.activityId {
                            Task { await LiveActivityService.shared.end(activityId: activityId) }
                        }
                        vm.delete(memo)
                    } label: {
                        Label("context.delete", systemImage: "trash")
                    }
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
            }
            .onDelete(perform: { indexSet in
                for index in indexSet {
                    let memo = vm.memos[index]
                    if let activityId = memo.activityId {
                        Task { await LiveActivityService.shared.end(activityId: activityId) }
                    }
                    vm.delete(memo)
                }
            })
            .onMove(perform: vm.reorder)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .environment(\.editMode, .constant(isEditing ? .active : .inactive))
    }
}
