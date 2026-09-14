import SwiftUI
import XCTest
@testable import VellurePresentation
import VellureCore

/// 설정의 글자 크기 행을 이미지로 렌더링해 파일로 남긴다.
///
/// 이 행은 설정 화면 아래쪽에 있어 시뮬레이터 스크린샷으로는 화면에 걸린다.
/// 슬라이더 값과 미리보기가 함께 움직이는지 여기서 확인한다.
@MainActor
final class TextScaleRowRenderTests: XCTestCase {

    private static let rowWidth: CGFloat = 360

    /// 범위의 양 끝과 기본값을 뽑아 미리보기가 실제로 따라 커지는지 본다.
    func test_render_textScaleRow() throws {
        let cases: [(String, CGFloat)] = [
            ("min", TextScale.range.lowerBound),
            ("default", TextScale.default),
            ("max", TextScale.range.upperBound)
        ]

        for (name, scale) in cases {
            let image = try render(scale: scale)
            XCTAssertGreaterThan(image.size.height, 0, "\(name) 렌더링 실패")
            try write(image, named: "text-scale-\(name)")
        }
    }

    /// 퍼센트 표기가 100%처럼 읽히는 값으로 나오는지 확인한다.
    /// 저장 키가 바뀌기 전에는 이 값이 0%로 나오는 문제가 있었다.
    func test_percentLabel_atDefault_shouldReadHundred() {
        XCTAssertEqual(TextScale.percentLabel(TextScale.default), "100%")
    }

    // MARK: - Helpers

    private func render(scale: CGFloat) throws -> UIImage {
        let content = TextScaleRow(scale: .constant(Double(scale)))
            .frame(width: Self.rowWidth)
            .environment(\.colorScheme, .dark)
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
