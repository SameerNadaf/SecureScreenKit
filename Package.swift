import PackageDescription

let package = Package(
    name: "SecureScreenKit",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "SecureScreenKit",
            targets: ["SecureScreenKit"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SecureScreenKit",
            dependencies: [],
            path: "Sources/SecureScreenKit"
        ),
    ]
)
