// swift-tools-version:5.3

import PackageDescription

let package = Package(
   name: "DMCoreLicensing",
   platforms: [
      .macOS(.v10_13),
   ],
   products: [
      .library(
         name: "DMCoreLicensing",
         targets: [
            "DMCoreLicensing",
         ]
      ),
   ],
   dependencies: [
      .package(name: "SwiftProtobuf", url: "https://github.com/apple/swift-protobuf.git", from: "1.13.0"),
      .package(url: "https://github.com/JanGorman/Hippolyte.git", from: "1.2.3"),
   ],
   targets: [
      .target(
         name: "DMCoreLicensing",
         dependencies: [
            "SwiftProtobuf"
         ],
         exclude: [
            "Schemas/",
         ]
      ),
      .testTarget(
         name: "DMCoreLicensingTests",
         dependencies: [
            "DMCoreLicensing",
            "Hippolyte",
         ]
      ),
   ]
)
