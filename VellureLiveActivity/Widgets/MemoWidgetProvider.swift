import AppIntents
import Foundation
import VellureCore
import WidgetKit

struct MemoWidgetProvider: AppIntentTimelineProvider {

    func placeholder(in context: Context) -> MemoWidgetEntry {
        .placeholder()
    }

    func snapshot(for configuration: SelectMemoIntent, in context: Context) async -> MemoWidgetEntry {
        // 위젯 갤러리 미리보기에서는 실제 데이터가 없을 수 있다. 그때는 예시를 보여준다.
        guard !context.isPreview else { return .placeholder() }
        return entry(for: configuration)
    }

    func timeline(for configuration: SelectMemoIntent, in context: Context) async -> Timeline<MemoWidgetEntry> {
        // D-day는 날짜가 바뀔 때만 값이 변한다. 자정에 한 번만 다시 그리면 충분하다.
        // (카운트다운류는 Text(date, style:)로 시스템이 실시간 렌더링한다)
        Timeline(entries: [entry(for: configuration)], policy: .after(Self.nextMidnight()))
    }

    private func entry(for configuration: SelectMemoIntent) -> MemoWidgetEntry {
        let all = MemoWidgetStore.widgetMemos().map(MemoSnapshot.init)

        // 메모를 고르지 않았으면 위젯 탭 정렬의 첫 번째를 보여준다.
        guard let selected = configuration.memo else {
            return MemoWidgetEntry(date: .now, memo: all.first, listMemos: all, isMissing: false)
        }

        // 고른 메모가 지워졌다면 조용히 다른 메모로 대체하지 않는다.
        // 사용자가 눈치채지 못한 채 엉뚱한 정보를 보게 되기 때문이다.
        guard let memo = MemoWidgetStore.memo(id: selected.id) else {
            return MemoWidgetEntry(date: .now, memo: nil, listMemos: all, isMissing: true)
        }

        return MemoWidgetEntry(
            date: .now,
            memo: MemoSnapshot(memo: memo),
            listMemos: all,
            isMissing: false
        )
    }

    private static func nextMidnight() -> Date {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: .now) ?? .now
        return calendar.startOfDay(for: tomorrow)
    }
}
