// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "todo-list",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "todo", targets: ["TodoCLI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0")
    ],
    targets: [
        .executableTarget(
            name: "TodoCLI",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ], path: "Sources/todo-list"
        )
    ]
)
