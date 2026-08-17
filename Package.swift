// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Erika",
    platforms: [
        .macOS(.v11),
        .iOS(.v13),
        .tvOS(.v13),
    ],
    products: [
        .library(name: "Erika", targets: ["Erika"]),
    ],
    targets: [
        .binaryTarget(
            name: "CErika",
            url: "https://github.com/AimesSoft/Erika/releases/download/v0.1.7/erika-swift-core-0.1.7.xcframework.zip",
            checksum: "9cafcd4a2dfd8d5b0b631659ed17de9f111aeaa92bf27ef5193f14232a5a6e3b"
        ),
        .target(
            name: "Erika",
            dependencies: ["CErika"],
            linkerSettings: [
                .linkedFramework("AVFoundation"),
                .linkedFramework("Metal"),
                .linkedFramework("QuartzCore"),
            ]
        ),
        .testTarget(name: "ErikaTests", dependencies: ["Erika"]),
    ]
)
