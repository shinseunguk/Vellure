import Foundation

/// D-day 표기를 만드는 단일 지점.
/// 앱 카드·Live Activity·위젯이 같은 메모에 같은 값을 보여야 하므로 여기서만 계산한다.
public enum DDayFormatter {

    /// 목표일까지 남은 일수를 `D-N` / `D-Day` / `D+N` 형태로 옮긴다.
    ///
    /// 시각이 아니라 **날짜** 기준이다. 양쪽을 `startOfDay`로 맞추지 않으면
    /// 남은 시간이 24시간을 넘는지에 따라 같은 날짜가 D-0과 D-1을 오간다.
    ///
    /// - Parameters:
    ///   - target: 목표 날짜
    ///   - reference: 기준 시점. 기본값은 현재 시각
    ///   - calendar: 날짜 경계를 판정할 달력. 기본값은 사용자 달력
    public static func string(
        for target: Date,
        from reference: Date = .now,
        calendar: Calendar = .current
    ) -> String {
        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: reference),
            to: calendar.startOfDay(for: target)
        ).day ?? 0

        if days > 0 { return "D-\(days)" }
        if days == 0 { return "D-Day" }
        return "D+\(abs(days))"
    }
}
