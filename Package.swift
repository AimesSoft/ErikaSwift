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
                .linkedFramework("Metal"),
                .linkedFramework("QuartzCore"),
            ]
        ),
        .testTarget(name: "ErikaTests", dependencies: ["Erika"]),
    ]
)
