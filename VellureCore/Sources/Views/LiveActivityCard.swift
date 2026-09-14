import SwiftUI

/// 잠금화면 Live Activity 카드.
///
/// 확장 타깃에 두면 앱에서 미리보기로 쓸 수 없고, `ActivityViewContext`는
/// ActivityKit만 만들 수 있어 밖에서 그려볼 수도 없다.
/// 값만 받는 뷰로 공용 계층에 두어 확장·앱 미리보기·렌더 테스트가 함께 쓴다.
///
/// 체크리스트·진행바 조작은 Live Activity에서 `Button(intent:)`로만 동작하는데,
/// 그 인텐트는 확장에 있다. 그래서 행을 감싸는 방법을 주입받는다.
public struct LiveActivityCard: View {
    /// 카드 안에서 눌린 행이 무엇을 해야 하는지.
    public enum RowAction: Sendable {
        case toggleItem(id: String)
        case stepProgress(up: Bool)
    }

    let state: MemoAttributes.ContentState
    let isStale: Bool
    /// 글자 크기 배율
    let scale: CGFloat
    /// 행을 감싸는 방법. 확장은 `Button(intent:)`로 감싸고, 미리보기는 그대로 둔다.
    let wrapRow: (AnyView, RowAction) -> AnyView

    public init(
        state: MemoAttributes.ContentState,
        isStale: Bool = false,
        scale: CGFloat = 1,
        wrapRow: @escaping (AnyView, RowAction) -> AnyView = { content, _ in content }
    ) {
        self.state = state
        self.isStale = isStale
        self.scale = scale
        self.wrapRow = wrapRow
    }

    /// 카드 기본 여백
    public static let cardPadding: CGFloat = 12
    /// 브랜드 표시와 본문 사이 여백
    public static let brandSpacing: CGFloat = 6
    /// 본문과 타입별 콘텐츠 사이 여백
    public static let contentSpacing = Theme.Metric.contentSpacing
    /// 체크리스트 행 간격
    public static let checkRowSpacing: CGFloat = 5
    // 잠금화면은 손에 들고 흘긋 보는 화면이라 앱·위젯보다 글자가 커야 한다.
    // 공용 토큰(Theme.Metric)은 위젯에 맞춰둔 값이므로 여기서 따로 정한다.

    /// 본문 글자 크기
    public static let contentFontSize: CGFloat = 17
    /// 체크리스트 항목 글자 크기.
    /// 항목이 실제 정보인데 본문보다 작으면 읽는 순서가 뒤집힌다.
    public static let itemFontSize: CGFloat = 15.5
    /// 체크박스 아이콘 크기. 항목 글자보다 살짝 크게 둔다.
    public static let checkboxSize: CGFloat = 17
    /// 브랜드 표시·만료 타이머 같은 보조 정보
    public static let captionFontSize: CGFloat = 12.5
    /// D-day·카운트다운 강조 숫자
    public static let highlightFontSize: CGFloat = 30

    /// 본문 글자색. 배경이 메모 색이라 라이트·다크 모두 흰색으로 고정한다.
    public static let label = Color.white
    /// 보조 글자색
    public static let secondaryLabel = Color.white.opacity(0.78)

    /// 카드 배경. 메모마다 다른 색을 그대로 카드에 쓴다.
    private var background: Color {
        Theme.memoSurface(for: state.colorTag)
    }
    private var hasContent: Bool {
        !state.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// 일반 메모는 본문이 카드의 전부라 가운데에 둔다.
    /// 다른 타입은 본문 아래에 체크리스트·숫자가 이어지므로 왼쪽 정렬을 유지해야
    /// 아래 내용과 시작선이 맞는다.
    private var isCentered: Bool { state.renderType == "plain" }

    public var body: some View {
        VStack(alignment: .leading, spacing: Self.contentSpacing) {
            VStack(alignment: .leading, spacing: Self.brandSpacing) {
                HStack(spacing: 8) {
                    Text(verbatim: brandText)
                        .font(.system(size: Self.captionFontSize * scale, weight: .semibold))
                        .foregroundStyle(Self.label)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    Spacer(minLength: 4)
                    expiryTimer
                }
                // 본문이 비면 이 행이 내용만큼만 넓어져 타이머가 끝까지 밀리지 않는다.
                // 카드 폭을 강제해 항상 우측 상단에 붙인다.
                .frame(maxWidth: .infinity)

                if hasContent {
                    Text(state.content)
                        .font(.system(size: Self.contentFontSize * scale, weight: .semibold))
                        .foregroundStyle(Self.label)
                        .lineLimit(contentLineLimit)
                        .truncationMode(.tail)
                        .multilineTextAlignment(isCentered ? .center : .leading)
                        .frame(maxWidth: .infinity, alignment: isCentered ? .center : .leading)
                }
            }

            lockScreenExtraContent
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        // 폭을 여기서 먼저 확정해야 안쪽 행들이 카드 폭을 물려받는다.
        // 패딩 뒤에 붙이면 스택은 이미 내용만큼만 넓어진 뒤라,
        // 만료 타이머가 우측 끝까지 밀리지 않는다.
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Self.cardPadding)
        // 배경을 뷰 안에서 직접 칠한다.
        // activityBackgroundTint에 적응형 색을 넘기면 시스템 외형 기준으로 해석되는 반면
        // 본문 글자색은 잠금화면 렌더 컨텍스트 기준으로 해석돼 서로 어긋난다.
        // (라이트 모드에서 흰 배경 + 흰 글씨가 되던 원인)
        // 같은 컨텍스트에서 함께 해석되도록 배경과 글자색을 모두 뷰 안에 둔다.
        .background(background)
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
                Image(systemName: isStale ? "exclamationmark.arrow.circlepath" : "timer")
                    .font(.system(size: 10.5 * scale, weight: .semibold))
                    .accessibilityHidden(true)

                // `expiresAt > .now` 비교로는 전환되지 않는다.
                // 앱이 종료된 상태에서는 뷰를 다시 그릴 계기가 없어 타이머가 0:00에 멈춘 채 남는다.
                // isStale은 staleDate 도달 시 ActivityKit이 뷰를 다시 그려주므로 이때만 신뢰할 수 있다.
                if !isStale {
                    Text(timerInterval: Date.now...expiresAt, countsDown: true)
                        .font(.system(size: Self.captionFontSize * scale, weight: .semibold))
                        // 고정 폭을 주지 않는다. 자릿수가 줄면 그만큼 좁아지며
                        // 아이콘과 숫자가 계속 붙어 있다.
                        .monospacedDigit()
                } else {
                    // 8시간이 지나면 갱신이 멈춘다. 타이머를 지우면 왜 멈췄는지 알 수 없으니
                    // 다시 올려야 한다는 사실을 알린다.
                    Text("la.expired")
                        .font(.system(size: Self.captionFontSize * scale, weight: .semibold))
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
                    .memoHighlightStyle(size: Self.highlightFontSize * scale)
                    .foregroundStyle(Self.label)
            }
        case "countdown":
            if let target = state.targetDate {
                Text(timerInterval: Date.now...target, countsDown: true)
                    .memoHighlightStyle(size: Self.highlightFontSize * scale)
                    .foregroundStyle(Self.label)
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
    private var checklistCapacity: Int { hasContent ? 3 : 4 }

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
                    .font(.system(size: Self.captionFontSize * scale))
                    .foregroundStyle(Self.secondaryLabel)
            }
        }
    }

    private func checkRow(_ item: LiveChecklistItem) -> some View {
        let row = HStack(spacing: 8) {
                Image(systemName: item.done ? "checkmark.square.fill" : "square")
                    .font(.system(size: Self.checkboxSize * scale))
                    .foregroundStyle(item.done ? Self.label : Self.secondaryLabel)
                Text(item.title)
                    .font(.system(size: Self.itemFontSize * scale))
                    .foregroundStyle(item.done ? Self.secondaryLabel : Self.label)
                    .strikethrough(item.done)
                    .lineLimit(1)
                    .truncationMode(.tail)
                // Spacer가 없으면 행 폭이 확정되지 않아 말줄임 대신 그대로 잘린다.
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityLabel(item.title)
        .accessibilityValue(item.done ? "a11y.item.checked" : "a11y.item.unchecked")

        return wrapRow(AnyView(row), .toggleItem(id: item.id))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Progress

    private func progressContent(_ progress: Double) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(Int(progress * 100))%")
                .font(.system(size: 13 * scale, weight: .bold))
                .foregroundStyle(Self.secondaryLabel)
                .monospacedDigit()

            HStack(spacing: 10) {
                stepButton(up: false, systemName: "minus")

                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .tint(Self.label)
                    .frame(maxWidth: .infinity)

                stepButton(up: true, systemName: "plus")
            }
        }
    }

    private func stepButton(up: Bool, systemName: String) -> some View {
        let control = Image(systemName: systemName)
            .font(.subheadline.weight(.bold))
            .foregroundStyle(Self.label)
            .frame(width: 28, height: 28)
            .background(.quaternary, in: Circle())
            .accessibilityLabel(up ? "a11y.progress.increase" : "a11y.progress.decrease")

        return wrapRow(AnyView(control), .stepProgress(up: up))
    }

    /// 카드가 Vellure에서 나왔음을 알리는 한 줄.
    private var brandText: String {
        guard let label = Self.typeLabel(state.renderType) else { return "Vellure" }
        return "Vellure · \(label)"
    }

    /// 렌더 타입을 사용자에게 보여줄 이름으로 옮긴다.
    public static func typeLabel(_ renderType: String) -> String? {
        RenderType(rawValue: renderType)?.displayName
    }
}
