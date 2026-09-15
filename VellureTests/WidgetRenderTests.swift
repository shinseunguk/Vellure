import SwiftUI
import WidgetKit
import XCTest
import VellureCore

/// 위젯 뷰를 이미지로 렌더링해 파일로 남긴다.
///
/// 위젯은 홈·잠금화면에 배치해야 볼 수 있어 자동화로 확인할 수 없다.
/// 실제 렌더 결과를 눈으로 확인할 수 있도록 PNG로 뽑아둔다.
@MainActor
final class WidgetRenderTests: XCTestCase {

    /// 렌더 결과를 남길 위치.
    /// 시뮬레이터 안에서 도는 프로세스라 호스트 경로를 직접 쓸 수 없다.
    /// 임시 디렉터리에 남기고 경로를 로그로 알린다.
    private var outputDirectory: URL {
        URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("widget-render")
    }

    private static let sample = MemoWidgetEntry.placeholder()

    func test_render_allFamilies() throws {
        let families: [(WidgetFamily, CGSize, String)] = [
            (.systemSmall, CGSize(width: 170, height: 170), "small"),
            (.systemMedium, CGSize(width: 364, height: 170), "medium"),
            (.accessoryRectangular, CGSize(width: 172, height: 76), "rectangular"),
            (.accessoryCircular, CGSize(width: 76, height: 76), "circular"),
            (.accessoryInline, CGSize(width: 250, height: 26), "inline")
        ]

        // 대부분의 사용자가 다크 모드로 본다. 배경 그라디언트는 두 모드에서 전혀 다르게 보인다.
        for scheme in [ColorScheme.light, .dark] {
            for (family, size, name) in families {
                let image = try render(family: family, size: size, scheme: scheme)
                XCTAssertGreaterThan(image.size.width, 0, "\(name) 렌더링 실패")
                try write(image, named: "\(name)-\(scheme == .dark ? "dark" : "light")")
            }
        }
    }

    // MARK: - Helpers

    private func render(family: WidgetFamily, size: CGSize, scheme: ColorScheme) throws -> UIImage {
        // 잠금화면 계열은 시스템이 단색(vibrant)으로 칠한다.
        // 배경만 어둡게 두면 검은 글씨가 묻히므로 전경색까지 흉내낸다.
        let content = MemoWidgetView(entry: Self.sample, familyOverride: family)
            .foregroundStyle(family.isAccessory ? Color.white : Theme.textPrimary)
            .frame(width: size.width, height: size.height)
            .background {
                if family.isAccessory {
                    Color.black
                } else {
                    WidgetBackground(tint: Self.sample.backgroundTint(for: family))
                }
            }

        let renderer = ImageRenderer(content: content.environment(\.colorScheme, scheme))
        renderer.scale = 3
        return try XCTUnwrap(renderer.uiImage)
    }

    private func write(_ image: UIImage, named name: String) throws {
        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
        let data = try XCTUnwrap(image.pngData())
        let url = outputDirectory.appendingPathComponent("\(name).png")
        try data.write(to: url)
        print("WIDGET_RENDER \(url.path)")
    }
}

private extension WidgetFamily {
    /// 잠금화면 계열은 시스템이 단색으로 렌더링하므로 어두운 배경 위에서 확인한다.
    var isAccessory: Bool {
        switch self {
        case .accessoryInline, .accessoryCircular, .accessoryRectangular: true
        default: false
        }
    }
}
