// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "TalentFinderCore",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "TalentFinderCore", targets: ["TalentFinderCore"])
    ],
    targets: [
        .target(name: "TalentFinderCore"),
        .testTarget(name: "TalentFinderCoreTests", dependencies: ["TalentFinderCore"])
    ]
)
