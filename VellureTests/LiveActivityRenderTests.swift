import SwiftUI
import XCTest
import VellureCore

/// 잠금화면 Live Activity를 이미지로 렌더링해 파일로 남긴다.
///
/// Live Activity는 실제로 띄워야 볼 수 있어 자동화로 확인할 수 없다.
/// 글자 크기·여백을 고칠 때 결과를 눈으로 대조하려고 둔다.
@MainActor
final class LiveActivityRenderTests: XCTestCase {

    /// 잠금화면 카드의 대략적인 크기.
    private static let cardSize = CGSize(width: 360, height: 160)

    /// 메모 색이 카드 배경이므로 네 색을 모두 확인해야 한다.
    func test_render_allColors() throws {
        for tag in ["green", "gold", "blue", "rose"] {
            let state = MemoAttributes.ContentState.sample(
                renderType: "plain",
                content: "주차 위치 B2 구역 47",
                colorTag: tag
            )
            let image = try render(state, scheme: .dark)
            XCTAssertGreaterThan(image.size.width, 0, "\(tag) 렌더링 실패")
            try write(image, named: "la-color-\(tag)")
        }
    }

    func test_render_lockScreenCards() throws {
        let cases: [(String, MemoAttributes.ContentState)] = [
            ("plain", .sample(renderType: "plain", content: "주차 위치 B2 구역 47")),
            ("checklist", .sample(
                renderType: "checklist",
                content: "외출 준비물",
                items: [
                    LiveChecklistItem(id: "1", title: "지갑", done: true),
                    LiveChecklistItem(id: "2", title: "충전기", done: false),
                    LiveChecklistItem(id: "3", title: "이어폰", done: false)
                ]
            )),
            ("empty", .sample(renderType: "plain", content: "")),
            ("countdown", .sample(
                renderType: "countdown",
                content: "팀 회의 시작",
                targetDate: Calendar.current.date(byAdding: .hour, value: 2, to: .now)
            ))
        ]

        for (name, state) in cases {
            for scheme in [ColorScheme.light, .dark] {
                let image = try render(state, scheme: scheme)
                XCTAssertGreaterThan(image.size.width, 0, "\(name) 렌더링 실패")
                try write(image, named: "la-\(name)-\(scheme == .dark ? "dark" : "light")")
            }
        }
    }

    // MARK: - Helpers

    private func render(_ state: MemoAttributes.ContentState, scheme: ColorScheme) throws -> UIImage {
        // 폭을 강제하면 내용이 카드 폭을 채우지 못하는 문제를 가린다.
        // 실제 잠금화면처럼 컨테이너만 주고 내용이 스스로 넓어지게 둔다.
        let content = VStack(spacing: 0) {
            LockScreenContent(state: state, memoId: "preview", isStale: false)
        }
        .frame(width: Self.cardSize.width, alignment: .leading)
        .frame(minHeight: Self.cardSize.height, alignment: .top)
        .environment(\.colorScheme, scheme)

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

private extension MemoAttributes.ContentState {
    static func sample(
        renderType: String,
        content: String,
        items: [LiveChecklistItem]? = nil,
        targetDate: Date? = nil,
        colorTag: String = "green"
    ) -> Self {
        MemoAttributes.ContentState(
            renderType: renderType,
            content: content,
            items: items,
            targetDate: targetDate,
            font: "default",
            colorTag: colorTag,
            updatedAt: .now,
            expiresAt: Calendar.current.date(byAdding: .hour, value: 6, to: .now)
        )
    }
}
