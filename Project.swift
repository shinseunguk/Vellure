import ProjectDescription

// MARK: - Constants

private let bundlePrefix = "dev.ukseung"
private let deploymentTargets: DeploymentTargets = .iOS("17.0")

private let baseSettings: SettingsDictionary = [
    "DEVELOPMENT_TEAM": "2D8WKJP7C4",
    "SWIFT_VERSION": "5.0",
    "MARKETING_VERSION": "1.0.0",
    "CURRENT_PROJECT_VERSION": "1",
]

// MARK: - Helpers

private func framework(
    name: String,
    dependencies: [TargetDependency] = []
) -> Target {
    .target(
        name: name,
        destinations: [.iPhone],
        product: .framework,
        bundleId: "\(bundlePrefix).\(name)",
        deploymentTargets: deploymentTargets,
        sources: ["\(name)/Sources/**"],
        dependencies: dependencies
    )
}

// MARK: - Project

let project = Project(
    name: "Vellure",
    options: .options(
        developmentRegion: "ko"
    ),
    settings: .settings(base: baseSettings),
    targets: [
        // MARK: Layers (Framework)
        framework(name: "VellureCore"),
        framework(
            name: "VellureData",
            dependencies: [.target(name: "VellureCore")]
        ),
        framework(
            name: "VellurePresentation",
            dependencies: [
                .target(name: "VellureCore"),
                .target(name: "VellureData"),
            ]
        ),

        // MARK: App
        .target(
            name: "Vellure",
            destinations: [.iPhone],
            product: .app,
            bundleId: "\(bundlePrefix).Vellure",
            deploymentTargets: deploymentTargets,
            infoPlist: .extendingDefault(with: [
                // 리터럴로 구워지지 않도록 빌드 설정 변수를 참조시킨다 (빌드 번호 주입에 필요)
                "CFBundleShortVersionString": "$(MARKETING_VERSION)",
                "CFBundleVersion": "$(CURRENT_PROJECT_VERSION)",
                "ITSAppUsesNonExemptEncryption": false,
                "UILaunchScreen": [
                    "UIColorName": "LaunchBackground",
                ],
                "NSSupportsLiveActivities": true,
                "UIApplicationSupportsIndirectInputEvents": true,
                "UISupportedInterfaceOrientations": [
                    "UIInterfaceOrientationPortrait",
                    "UIInterfaceOrientationLandscapeLeft",
                    "UIInterfaceOrientationLandscapeRight",
                ],
            ]),
            sources: [
                "Vellure/App/**/*.swift",
                "Vellure/Intents/**/*.swift",
            ],
            resources: [
                "Vellure/Resources/**",
                "Vellure/Assets.xcassets",
            ],
            entitlements: "Vellure/App/Vellure.entitlements",
            dependencies: [
                .target(name: "VellureCore"),
                .target(name: "VellureData"),
                .target(name: "VellurePresentation"),
                .target(name: "VellureLiveActivity"),
            ]
        ),

        // MARK: Widget Extension
        .target(
            name: "VellureLiveActivity",
            destinations: [.iPhone],
            product: .appExtension,
            bundleId: "\(bundlePrefix).Vellure.VellureLiveActivity",
            deploymentTargets: deploymentTargets,
            infoPlist: .file(path: "VellureLiveActivity/Info.plist"),
            sources: ["VellureLiveActivity/**/*.swift"],
            // 위젯 익스텐션은 앱과 별도 번들이라 앱의 Localizable.strings를 찾지 못한다.
            // 포함하지 않으면 잠금화면에 키 문자열이 그대로 노출된다.
            resources: [
                "VellureLiveActivity/Assets.xcassets",
                "Vellure/Resources/**/*.strings",
            ],
            entitlements: "VellureLiveActivity/VellureLiveActivity.entitlements",
            dependencies: [.target(name: "VellureCore")]
        ),

        // MARK: Tests
        .target(
            name: "VellureTests",
            destinations: [.iPhone],
            product: .unitTests,
            bundleId: "\(bundlePrefix).VellureTests",
            deploymentTargets: deploymentTargets,
            sources: ["VellureTests/**/*.swift"],
            dependencies: [.target(name: "Vellure")]
        ),
        .target(
            name: "VellureUITests",
            destinations: [.iPhone],
            product: .uiTests,
            bundleId: "\(bundlePrefix).VellureUITests",
            deploymentTargets: deploymentTargets,
            sources: ["VellureUITests/**/*.swift"],
            dependencies: [.target(name: "Vellure")]
        ),
    ]
)
