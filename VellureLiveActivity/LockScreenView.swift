import AppIntents
import SwiftUI
import UIKit
import WidgetKit
import VellureCore

struct LockScreenView: View {
    /// 카드 기본 여백
    private static let cardPadding: CGFloat = 12
    /// 브랜드 표시와 본문 사이 여백
    private static let brandSpacing: CGFloat = 6
    /// 본문과 타입별 콘텐츠 사이 여백
    private static let contentSpacing: CGFloat = 8
    /// 체크리스트 행 간격
    private static let checkRowSpacing: CGFloat = 5
    /// 본문 글자 크기
    private static let contentFontSize: CGFloat = 15
    /// 체크리스트 항목 글자 크기
    private static let itemFontSize: CGFloat = 13
    /// D-day·카운트다운 강조 숫자 크기
    private static let highlightFontSize: CGFloat = 24

    /// 카드 배경. 라이트=흰색, 다크=검은색
    private static let background = Color(uiColor: .systemBackground)
    /// 본문 글자색. 라이트=검은색, 다크=흰색
    private static let label = Color(uiColor: .label)
    /// 보조 글자색
    private static let secondaryLabel = Color(uiColor: .secondaryLabel)

    let context: ActivityViewContext<MemoAttributes>

    private var state: MemoAttributes.ContentState { context.state }
    private var tint: Color { colorFromTag(state.colorTag) }
    private var hasContent: Bool {
        !state.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Self.contentSpacing) {
            VStack(alignment: .leading, spacing: Self.brandSpacing) {
                BrandLabel(tint: tint, renderType: state.renderType)

                if hasContent {
                    Text(state.content)
                        .font(.system(size: Self.contentFontSize, weight: .semibold))
                        .fontDesign(fontDesign(from: state.font))
                        .foregroundStyle(Self.label)
                        .lineLimit(contentLineLimit)
                        .truncationMode(.tail)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            lockScreenExtraContent
        }
        .padding(Self.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        // 배경을 뷰 안에서 직접 칠한다.
        // activityBackgroundTint에 적응형 색을 넘기면 시스템 외형 기준으로 해석되는 반면
        // 본문 글자색은 잠금화면 렌더 컨텍스트 기준으로 해석돼 서로 어긋난다.
        // (라이트 모드에서 흰 배경 + 흰 글씨가 되던 원인)
        // 같은 컨텍스트에서 함께 해석되도록 배경과 글자색을 모두 뷰 안에 둔다.
        .background(Self.background)
        .activitySystemActionForegroundColor(Self.label)
    }

    /// 타입별 본문 최대 줄 수.
    /// 잠금화면 LA는 높이 상한이 있어, 아래 콘텐츠가 클수록 본문 줄 수를 줄인다.
    private var contentLineLimit: Int {
        switch state.renderType {
        case "checklist": 1
        case "progress": 2
        case "dday", "countdown": 3
        default: 4
        }
    }

    // MARK: - Extra Content (타입별 본문 콘텐츠)

    @ViewBuilder
    private var lockScreenExtraContent: some View {
        switch state.renderType {
        case "dday":
            if let target = state.targetDate {
                Text(ddayString(target))
                    .font(.system(size: Self.highlightFontSize, weight: .heavy))
                    .foregroundStyle(tint)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        case "countdown":
            if let target = state.targetDate {
                Text(timerInterval: Date.now...target, countsDown: true)
                    .font(.system(size: Self.highlightFontSize, weight: .heavy))
                    .foregroundStyle(tint)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        case "checklist":
            if let items = state.items {
                checklistContent(items)
            }
        case "progress":
            if let progress = state.progress {
                progressContent(progress)
            }
        default:
            EmptyView()
        }
    }

    // MARK: - Checklist

    /// 본문 유무에 따라 달라지는 최대 표시 행 수.
    /// 남은 개수 안내("외 N개")도 한 행을 차지하므로 같은 예산에서 함께 계산한다.
    private var checklistCapacity: Int { hasContent ? 4 : 5 }

    @ViewBuilder
    private func checklistContent(_ items: [LiveChecklistItem]) -> some View {
        let showsOverflow = items.count > checklistCapacity
        let visibleCount = showsOverflow ? checklistCapacity - 1 : checklistCapacity

        VStack(alignment: .leading, spacing: Self.checkRowSpacing) {
            ForEach(items.prefix(visibleCount), id: \.id) { item in
                checkRow(item)
            }
            if showsOverflow {
                Text("외 \(items.count - visibleCount)개")
                    .font(.system(size: 11))
                    .foregroundStyle(Self.secondaryLabel)
            }
        }
    }

    private func checkRow(_ item: LiveChecklistItem) -> some View {
        Button(intent: ToggleItemIntent(
            memoId: context.attributes.memoId,
            itemId: item.id
        )) {
            HStack(spacing: 8) {
                Image(systemName: item.done ? "checkmark.square.fill" : "square")
                    .font(.system(size: 15))
                    .foregroundStyle(item.done ? tint : Self.secondaryLabel)
                Text(item.title)
                    .font(.system(size: Self.itemFontSize))
                    .foregroundStyle(item.done ? Self.secondaryLabel : Self.label)
                    .strikethrough(item.done)
                    .lineLimit(1)
                    .truncationMode(.tail)
                // Spacer가 없으면 행 폭이 확정되지 않아 말줄임 대신 그대로 잘린다.
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Progress

    private func progressContent(_ progress: Double) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(Int(progress * 100))%")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Self.secondaryLabel)
                .monospacedDigit()

            HStack(spacing: 10) {
                stepButton(direction: "down", systemName: "minus")

                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .tint(tint)
                    .frame(maxWidth: .infinity)

                stepButton(direction: "up", systemName: "plus")
            }
        }
    }

    private func stepButton(direction: String, systemName: String) -> some View {
        Button(intent: StepProgressIntent(
            memoId: context.attributes.memoId,
            direction: direction
        )) {
            Image(systemName: systemName)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Self.label)
                .frame(width: 28, height: 28)
                .background(.quaternary, in: Circle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func ddayString(_ target: Date) -> String {
        let days = Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: .now),
            to: Calendar.current.startOfDay(for: target)
        ).day ?? 0
        if days > 0 { return "D-\(days)" }
        if days == 0 { return "D-Day" }
        return "D+\(abs(days))"
    }

    private func fontDesign(from fontTag: String) -> Font.Design? {
        switch fontTag {
        case "rounded": .rounded
        case "serif": .serif
        case "mono": .monospaced
        default: nil
        }
    }

    private func colorFromTag(_ tag: String) -> Color {
        switch tag {
        case "green": Color(red: 31 / 255, green: 169 / 255, blue: 124 / 255)
        case "gold": Color(red: 239 / 255, green: 150 / 255, blue: 69 / 255)
        case "blue": Color(red: 75 / 255, green: 150 / 255, blue: 243 / 255)
        case "rose": Color(red: 238 / 255, green: 123 / 255, blue: 162 / 255)
        default: Color(red: 31 / 255, green: 169 / 255, blue: 124 / 255)
        }
    }
}
