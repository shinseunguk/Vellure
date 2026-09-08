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
    private static let contentSpacing = Theme.Metric.contentSpacing
    /// 체크리스트 행 간격
    private static let checkRowSpacing: CGFloat = 5
    /// 본문 글자 크기
    private static let contentFontSize = Theme.Metric.contentFontSize
    /// 체크리스트 항목 글자 크기
    private static let itemFontSize: CGFloat = 13

    /// 카드 배경. 라이트=흰색, 다크=검은색
    private static let background = Color(uiColor: .systemBackground)
    /// 본문 글자색. 라이트=검은색, 다크=흰색
    private static let label = Color(uiColor: .label)
    /// 보조 글자색
    private static let secondaryLabel = Color(uiColor: .secondaryLabel)

    let context: ActivityViewContext<MemoAttributes>

    private var state: MemoAttributes.ContentState { context.state }
    private var tint: Color { Theme.memoColor(for: state.colorTag) }
    private var hasContent: Bool {
        !state.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Self.contentSpacing) {
            VStack(alignment: .leading, spacing: Self.brandSpacing) {
                HStack(spacing: 8) {
                    BrandLabel(tint: tint, renderType: state.renderType)
                    Spacer(minLength: 4)
                    expiryTimer
                }

                if hasContent {
                    Text(state.content)
                        .font(.system(size: Self.contentFontSize, weight: .semibold))
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

    // MARK: - Expiry Timer

    /// 잠금화면에서 이 메모가 언제까지 살아있는지 알린다.
    /// 12시간이 아니라 8시간(활성 상한) 기준이다.
    /// 8시간이 지나면 아일랜드에서 사라지고 잠금화면에서도 갱신이 멈추므로,
    /// 12시간을 세면 마지막 4시간이 사실과 달라진다.
    @ViewBuilder
    private var expiryTimer: some View {
        if let expiresAt = state.expiresAt {
            HStack(spacing: 3) {
                Image(systemName: context.isStale ? "exclamationmark.arrow.circlepath" : "timer")
                    .font(.system(size: 9, weight: .semibold))
                    .accessibilityHidden(true)

                // `expiresAt > .now` 비교로는 전환되지 않는다.
                // 앱이 종료된 상태에서는 뷰를 다시 그릴 계기가 없어 타이머가 0:00에 멈춘 채 남는다.
                // isStale은 staleDate 도달 시 ActivityKit이 뷰를 다시 그려주므로 이때만 신뢰할 수 있다.
                if !context.isStale {
                    Text(timerInterval: Date.now...expiresAt, countsDown: true)
                        .font(.system(size: 11, weight: .semibold))
                        // 고정 폭을 주지 않는다. 자릿수가 줄면 그만큼 좁아지며
                        // 아이콘과 숫자가 계속 붙어 있다.
                        .monospacedDigit()
                } else {
                    // 8시간이 지나면 갱신이 멈춘다. 타이머를 지우면 왜 멈췄는지 알 수 없으니
                    // 다시 올려야 한다는 사실을 알린다.
                    Text("la.expired")
                        .font(.system(size: 11, weight: .semibold))
                        .lineLimit(1)
                }
            }
            .foregroundStyle(Self.secondaryLabel)
            .lineLimit(1)
        }
    }

    // MARK: - Extra Content (타입별 본문 콘텐츠)

    @ViewBuilder
    private var lockScreenExtraContent: some View {
        switch state.renderType {
        case "dday":
            if let target = state.targetDate {
                Text(DDayFormatter.string(for: target))
                    .memoHighlightStyle()
                    .foregroundStyle(tint)
            }
        case "countdown":
            if let target = state.targetDate {
                Text(timerInterval: Date.now...target, countsDown: true)
                    .memoHighlightStyle()
                    .foregroundStyle(tint)
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
        .accessibilityLabel(item.title)
        .accessibilityValue(item.done ? "a11y.item.checked" : "a11y.item.unchecked")
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
        .accessibilityLabel(direction == "up" ? "a11y.progress.increase" : "a11y.progress.decrease")
    }
}
