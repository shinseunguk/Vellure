import SwiftUI
import VellureCore
import WidgetKit

/// 작성 중인 메모가 위젯에 어떻게 보이는지 미리 보여준다.
///
/// 위젯 탭 메모는 잠금화면에 올릴 수 없으므로 Live Activity 미리보기를 보여주면
/// 실제로 볼 수 없는 모습을 보여주는 셈이 된다.
///
/// 같은 메모라도 한 칸짜리와 목록은 담기는 정보가 달라, 둘 다 볼 수 있어야 한다.
struct WidgetPreview: View {
    let preview: WidgetPreviewData

    private var entry: MemoWidgetEntry { preview.entry }

    /// 작성 중인 메모가 목록 위젯에 담기지 못하는지.
    /// 담기지 못하면 미리보기에 정작 그 메모가 없어, 이유를 알려주지 않으면 오해한다.
    private var isDraftBeyondList: Bool {
        preview.draftIndex >= MemoWidgetView.listRowLimit
    }

    @State private var place: Place = .home

    /// 위젯을 놓을 자리. 실제로 배치할 수 있는 칸을 그대로 따른다.
    private enum Place: String, CaseIterable, Identifiable {
        case home
        case list

        var id: String { rawValue }

        var titleKey: LocalizedStringKey {
            switch self {
            case .home: "edit.widgetPreview.home"
            case .list: "edit.widgetPreview.list"
            }
        }

        var hintKey: LocalizedStringKey {
            switch self {
            case .home: "edit.widgetPreview.home.hint"
            case .list: "edit.widgetPreview.list.hint"
            }
        }
    }

    /// small 위젯 한 칸의 실제 크기에 가깝게 잡는다.
    /// 위젯은 칸 크기가 정해져 있어, 크기를 바꾸면 줄바꿈과 말줄임이 달라진다.
    private static let smallSide: CGFloat = 158
    private static let smallCornerRadius: CGFloat = 22
    /// medium 위젯 한 칸의 실제 크기.
    private static let mediumSize = CGSize(width: 338, height: 158)
    /// medium 칸을 좁은 화면에 맞추는 축소 비율.
    private static let listScale: CGFloat = 0.86

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("edit.section.widgetPreview")
                .scaledFont(13, weight: .semibold)
                .foregroundStyle(Theme.textSecondary)

            placePicker

            previewCard
                .frame(maxWidth: .infinity, alignment: .center)
                // 위젯 조작은 홈화면에서만 동작한다. 여기서는 보여주기만 한다.
                .allowsHitTesting(false)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(place.titleKey)

            Text(place.hintKey)
                .scaledFont(12)
                .foregroundStyle(Theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .center)

            if place == .list, isDraftBeyondList {
                Text("edit.widgetPreview.list.overflow")
                    .scaledFont(12)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    private var placePicker: some View {
        HStack(spacing: 8) {
            ForEach(Place.allCases) { candidate in
                Button {
                    place = candidate
                } label: {
                    Text(candidate.titleKey)
                        .scaledFont(13, weight: .semibold)
                        .foregroundStyle(place == candidate ? .white : Theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(place == candidate ? Theme.accent : Theme.chipBackground)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(place == candidate ? Color.clear : Theme.chipBorder, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(place == candidate ? .isSelected : [])
            }
        }
    }

    @ViewBuilder
    private var previewCard: some View {
        switch place {
        case .home: homePreview
        case .list: listPreview
        }
    }

    private var homePreview: some View {
        MemoWidgetView(entry: entry, familyOverride: .systemSmall)
            .padding(14)
            .frame(width: Self.smallSide, height: Self.smallSide)
            .background(WidgetBackground(tint: entry.backgroundTint(for: .systemSmall)))
            .clipShape(RoundedRectangle(cornerRadius: Self.smallCornerRadius, style: .continuous))
    }

    /// 홈화면 medium 칸. 위젯 탭 정렬 순서대로 여러 건을 담는다.
    ///
    /// 실제 폭이 화면보다 넓을 수 있어 그대로 두면 잘린다.
    /// 비율을 지킨 채 줄여, 몇 건이 들어가고 어디서 잘리는지가 그대로 보이게 한다.
    private var listPreview: some View {
        MemoWidgetView(entry: entry, familyOverride: .systemMedium)
            .padding(14)
            .frame(width: Self.mediumSize.width, height: Self.mediumSize.height)
            .background(WidgetBackground(tint: entry.backgroundTint(for: .systemMedium)))
            .clipShape(RoundedRectangle(cornerRadius: Self.smallCornerRadius, style: .continuous))
            .scaleEffect(Self.listScale)
            .frame(
                width: Self.mediumSize.width * Self.listScale,
                height: Self.mediumSize.height * Self.listScale
            )
    }
}
