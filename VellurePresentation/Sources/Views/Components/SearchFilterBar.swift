import SwiftUI
import VellureCore

/// 홈 목록 상단의 검색 필드와 필터 칩.
struct SearchFilterBar: View {
    /// 필드·칩 사이 간격
    private static let rowSpacing: CGFloat = 10
    /// 칩 사이 간격
    private static let chipSpacing: CGFloat = 6

    @Binding var searchText: String
    @Binding var typeFilter: RenderType?
    @Binding var displayFilter: DisplayFilter

    var body: some View {
        VStack(spacing: Self.rowSpacing) {
            searchField

            // 성격이 다른 두 축을 같은 칩으로 나열하면 무엇이 무엇인지 구분되지 않는다.
            // 표시 상태는 세그먼트, 타입은 칩으로 시각 언어를 나눈다.
            displayPicker

            typeChips
        }
    }

    private var displayPicker: some View {
        Picker("", selection: $displayFilter) {
            ForEach(DisplayFilter.allCases, id: \.self) { filter in
                Text(LocalizedStringKey(filter.labelKey)).tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .padding(.horizontal, 20)
    }

    private var typeChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Self.chipSpacing) {
                chip(title: Text("filter.type.all"), isSelected: typeFilter == nil) {
                    typeFilter = nil
                }

                ForEach(RenderType.allCases, id: \.self) { type in
                    chip(
                        title: Text(LocalizedStringKey(typeLabelKey(type))),
                        isSelected: typeFilter == type
                    ) {
                        typeFilter = (typeFilter == type) ? nil : type
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .scaledFont(13, weight: .semibold)
                .foregroundStyle(Theme.textSecondary)
                .accessibilityHidden(true)

            TextField(String(localized: "search.placeholder"), text: $searchText)
                .scaledFont(14)
                .foregroundStyle(Theme.textPrimary)
                .submitLabel(.search)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .scaledFont(14)
                        .foregroundStyle(Theme.textSecondary)
                }
                .accessibilityLabel("a11y.search.clear")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(Theme.chipBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal, 20)
    }

    private func chip(title: Text, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            title
                .scaledFont(12, weight: .semibold)
                .foregroundStyle(isSelected ? .white : Theme.textSecondary)
                .lineLimit(1)
                .padding(.horizontal, 11)
                .padding(.vertical, 6)
                .background(isSelected ? Theme.accent : Theme.chipBackground)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func typeLabelKey(_ type: RenderType) -> String {
        switch type {
        case .plain: "type.plain"
        case .checklist: "type.checklist"
        case .dday: "type.dday"
        case .countdown: "type.countdown"
        case .progress: "type.progress"
        }
    }
}
