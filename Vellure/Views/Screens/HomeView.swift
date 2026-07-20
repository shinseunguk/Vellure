import SwiftUI

struct HomeView: View {
    @Environment(MemoRepository.self) private var repository
    @State private var viewModel: MemoListViewModel?
    @State private var showNewMemo = false
    @State private var selectedMemo: Memo?
    @State private var showSettings = false

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
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text(Date.now.formatted(.dateTime.month().day().weekday(.wide)))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
                Text("메모")
                    .font(.system(size: 27, weight: .heavy))
                    .foregroundStyle(Theme.textPrimary)
            }

            Spacer()

            HStack(spacing: 9) {
                Button { showNewMemo = true } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .bold))
                        Text("새 메모")
                            .font(.system(size: 13.5, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 17)
                    .padding(.vertical, 10)
                    .background(Theme.accent)
                    .clipShape(Capsule())
                }

                Button { showSettings = true } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 17))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 38, height: 38)
                        .background(Theme.chipBackground)
                        .clipShape(Circle())
                }
            }
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
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
            }
            .onDelete(perform: { indexSet in
                for index in indexSet {
                    vm.delete(vm.memos[index])
                }
            })
            .onMove(perform: vm.reorder)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}
