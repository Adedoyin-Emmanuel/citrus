// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Citrus",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Citrus", targets: ["Citrus"])
    ],
    targets: [
        .executableTarget(
            name: "Citrus",
            path: "Sources/Citrus",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
