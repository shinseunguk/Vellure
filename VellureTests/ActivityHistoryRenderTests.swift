import SwiftUI
import XCTest
@testable import VellurePresentation
import VellureCore

/// 게시 이력 목록을 이미지로 렌더링해 파일로 남긴다.
///
/// 이 화면은 설정 아래쪽에 있어 시뮬레이터 스크린샷으로는 화면에 걸리고,
/// 이력을 쌓으려면 실제로 카드를 올렸다 내려야 해서 손으로 확인하기 어렵다.
@MainActor
final class ActivityHistoryRenderTests: XCTestCase {

    private static let width: CGFloat = 360

    func test_render_activityHistory() throws {
        let now = Date()
        let records: [ActivityRecord] = [
            // 앱이 내린 적 없는데 사라진 건 — 주황색으로 눈에 띄어야 한다
            ActivityRecord(
                memoId: "1", title: "주차 위치 B2 구역 47", displayMode: "pinned",
                startedAt: now.addingTimeInterval(-300 * 60),
                endedAt: now.addingTimeInterval(-263 * 60),
                reason: .disappeared
            ),
            ActivityRecord(
                memoId: "2", title: "외출 준비물", displayMode: "pinned",
                startedAt: now.addingTimeInterval(-1000 * 60),
                endedAt: now.addingTimeInterval(-520 * 60),
                reason: .expired
            ),
            ActivityRecord(
                memoId: "3", title: "팀 회의 시작", displayMode: "autoClear",
                startedAt: now.addingTimeInterval(-1400 * 60),
                endedAt: now.addingTimeInterval(-1385 * 60),
                reason: .user
            ),
            // 아직 떠 있는 건
            ActivityRecord(
                memoId: "4", title: "ㅋㅋㅋㅋㅋㅋㅋㅋ", displayMode: "pinned",
                startedAt: now.addingTimeInterval(-12 * 60)
            )
        ]

        for scheme in [ColorScheme.dark, .light] {
            let image = try render(records, scheme: scheme)
            XCTAssertGreaterThan(image.size.height, 0, "렌더링 실패")
            try write(image, named: "history-\(scheme == .dark ? "dark" : "light")")
        }
    }

    // MARK: - Helpers

    private func render(_ records: [ActivityRecord], scheme: ColorScheme) throws -> UIImage {
        let content = ActivityHistoryView(records: records)
            .padding(20)
            .frame(width: Self.width)
            .environment(\.colorScheme, scheme)
            .background(Theme.background)

        let renderer = ImageRenderer(content: content)
        renderer.scale = 3
        return try XCTUnwrap(renderer.uiImage)
    }

    private func write(_ image: UIImage, named name: String) throws {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("la-render")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("\(name).png")
        try XCTUnwrap(image.pngData()).write(to: url)
        print("LA_RENDER \(url.path)")
    }
}
