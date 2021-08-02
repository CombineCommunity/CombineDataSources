// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "CombineDataSources",
    platforms: [
      .iOS(.v13),
      .tvOS(.v13),
    ],
    products: [
        .library(
            name: "CombineDataSources",
            targets: ["CombineDataSources"]),
    ],
    targets: [
        .target(
            name: "CombineDataSources",
            dependencies: []),
        .testTarget(
            name: "CombineDataSourcesTests",
            dependencies: ["CombineDataSources"]),
    ]
)
