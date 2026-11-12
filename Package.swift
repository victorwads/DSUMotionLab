// swift-tools-version: 6.0
import PackageDescription
let package = Package(name: "DSUMotionLab", platforms: [.macOS(.v14)], products: [.executable(name: "DSUMotionLab", targets: ["DSUMotionLab"])], targets: [.executableTarget(name: "DSUMotionLab", resources: [.process("Resources")]), .testTarget(name: "DSUMotionLabTests", dependencies: ["DSUMotionLab"])], swiftLanguageModes: [.v5])
