import ProjectDescription

// MARK: - Constants

private let bundlePrefix = "com.uk"
private let deploymentTargets: DeploymentTargets = .iOS("17.0")

private let baseSettings: SettingsDictionary = [
    "DEVELOPMENT_TEAM": "S3JUP5Z7K9",
    "SWIFT_VERSION": "5.0",
    "MARKETING_VERSION": "1.0",
    "CURRENT_PROJECT_VERSION": "1",
]

// MARK: - Helpers

private func framework(
    name: String,
    dependencies: [TargetDependency] = []
) -> Target {
    .target(
        name: name,
        destinations: .iOS,
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
            destinations: .iOS,
            product: .app,
            bundleId: "\(bundlePrefix).Vellure",
            deploymentTargets: deploymentTargets,
            infoPlist: .extendingDefault(with: [
                "UILaunchScreen": [:],
                "NSSupportsLiveActivities": true,
                "UIApplicationSupportsIndirectInputEvents": true,
                "UISupportedInterfaceOrientations": [
                    "UIInterfaceOrientationPortrait",
                    "UIInterfaceOrientationLandscapeLeft",
                    "UIInterfaceOrientationLandscapeRight",
                ],
                "UISupportedInterfaceOrientations~ipad": [
                    "UIInterfaceOrientationPortrait",
                    "UIInterfaceOrientationPortraitUpsideDown",
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
            destinations: .iOS,
            product: .appExtension,
            bundleId: "\(bundlePrefix).Vellure.VellureLiveActivity",
            deploymentTargets: deploymentTargets,
            infoPlist: .file(path: "VellureLiveActivity/Info.plist"),
            sources: ["VellureLiveActivity/**/*.swift"],
            resources: ["VellureLiveActivity/Assets.xcassets"],
            entitlements: "VellureLiveActivity/VellureLiveActivity.entitlements",
            dependencies: [.target(name: "VellureCore")]
        ),

        // MARK: Tests
        .target(
            name: "VellureTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "\(bundlePrefix).VellureTests",
            deploymentTargets: deploymentTargets,
            sources: ["VellureTests/**/*.swift"],
            dependencies: [.target(name: "Vellure")]
        ),
        .target(
            name: "VellureUITests",
            destinations: .iOS,
            product: .uiTests,
            bundleId: "\(bundlePrefix).VellureUITests",
            deploymentTargets: deploymentTargets,
            sources: ["VellureUITests/**/*.swift"],
            dependencies: [.target(name: "Vellure")]
        ),
    ]
)
