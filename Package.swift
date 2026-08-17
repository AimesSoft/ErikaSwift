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
            checksum: "95f546811e9c5224640cf36d94a94561cc062ccb6b1a6fd616be128d64e70c29"
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
