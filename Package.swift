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
            url: "https://github.com/AimesSoft/Erika/releases/download/v0.1.8/erika-swift-core-0.1.8.xcframework.zip",
            checksum: "48a079ba937ff6a7a91b08adaed9cd32251181b9e882747652f8d9eab97f6f67"
        ),
        .target(
            name: "Erika",
            dependencies: ["CErika"],
            linkerSettings: [
                .linkedFramework("AVFoundation"),
                .linkedFramework("ApplicationServices", .when(platforms: [.macOS])),
                .linkedFramework("AudioToolbox"),
                .linkedFramework("CoreAudio", .when(platforms: [.macOS])),
                .linkedFramework("CoreFoundation"),
                .linkedFramework("CoreGraphics"),
                .linkedFramework("CoreMedia"),
                .linkedFramework("CoreText"),
                .linkedFramework("CoreVideo"),
                .linkedFramework("Metal"),
                .linkedFramework("QuartzCore"),
                .linkedFramework("VideoToolbox"),
                .linkedLibrary("bz2"),
                .linkedLibrary("iconv"),
                .linkedLibrary("z"),
            ]
        ),
        .testTarget(name: "ErikaTests", dependencies: ["Erika"]),
    ]
)
