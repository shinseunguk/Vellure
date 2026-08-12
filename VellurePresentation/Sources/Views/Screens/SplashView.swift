import SwiftUI
import VellureCore

/// 정적 런치스크린(배경색)과 이어지는 인앱 애니메이션 스플래시.
/// 로고가 스케일업+페이드인 → 워드마크 페이드인 → `onFinished`로 홈 전환.
public struct SplashView: View {
    private let onFinished: () -> Void

    @State private var logoScale: CGFloat = Metric.initialLogoScale
    @State private var logoOpacity: Double = 0

    private enum Metric {
        static let logoSize: CGFloat = 108
        static let cornerRadius: CGFloat = 24
        static let initialLogoScale: CGFloat = 0.82
        static let holdNanoseconds: UInt64 = 1_100_000_000
    }

    public init(onFinished: @escaping () -> Void) {
        self.onFinished = onFinished
    }

    public var body: some View {
        ZStack {
            Theme.background
                .ignoresSafeArea()

            Image("AppLogo", bundle: .main)
                .resizable()
                .scaledToFit()
                .frame(width: Metric.logoSize, height: Metric.logoSize)
                .clipShape(RoundedRectangle(cornerRadius: Metric.cornerRadius, style: .continuous))
                .scaleEffect(logoScale)
                .opacity(logoOpacity)
        }
        .task {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.7)) {
                logoScale = 1
                logoOpacity = 1
            }
            try? await Task.sleep(nanoseconds: Metric.holdNanoseconds)
            onFinished()
        }
    }
}

#if DEBUG
#Preview("스플래시") {
    SplashView {}
}
#endif
