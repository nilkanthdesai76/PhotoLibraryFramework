// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PhotoLibraryFramework",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "PhotoLibraryFramework",
            targets: ["PhotoLibraryFramework"]
        ),
    ],
    targets: [
        .target(
            name: "PhotoLibraryFramework",
            dependencies: [],
            path: "Sources/PhotoLibraryFramework",
            resources: []
        ),
        .testTarget(
            name: "PhotoLibraryFrameworkTests",
            dependencies: ["PhotoLibraryFramework"],
            path: "Tests/PhotoLibraryFrameworkTests"
        ),
    ],
    swiftLanguageVersions: [.v5]
)