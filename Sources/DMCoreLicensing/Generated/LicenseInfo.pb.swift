// DO NOT EDIT.
// swift-format-ignore-file
//
// Generated by the Swift generator plugin for the protocol buffer compiler.
// Source: LicenseInfo.proto
//
// For information on using the generated types, please see the documentation:
//   https://github.com/apple/swift-protobuf/

// MIT License
//
// Copyright © 2019 Darren Mo.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation
import SwiftProtobuf

// If the compiler emits an error on this type, it is because this file
// was generated by a version of the `protoc` Swift plug-in that is
// incompatible with the version of SwiftProtobuf to which you are linking.
// Please ensure that you are building against the same version of the API
// that was used to generate this file.
fileprivate struct _GeneratedWithProtocGenSwiftVersion: SwiftProtobuf.ProtobufAPIVersionCheck {
  struct _2: SwiftProtobuf.ProtobufAPIVersion_2 {}
  typealias Version = _2
}

struct LicenseInfo {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var deviceUuid: Data = Data()

  var specificInfo: LicenseInfo.OneOf_SpecificInfo? = nil

  var trial: TrialLicenseInfo {
    get {
      if case .trial(let v)? = specificInfo {return v}
      return TrialLicenseInfo()
    }
    set {specificInfo = .trial(newValue)}
  }

  var purchased: PurchasedLicenseInfo {
    get {
      if case .purchased(let v)? = specificInfo {return v}
      return PurchasedLicenseInfo()
    }
    set {specificInfo = .purchased(newValue)}
  }

  var extraInfo: Data = Data()

  var unknownFields = SwiftProtobuf.UnknownStorage()

  enum OneOf_SpecificInfo: Equatable {
    case trial(TrialLicenseInfo)
    case purchased(PurchasedLicenseInfo)

  #if !swift(>=4.1)
    static func ==(lhs: LicenseInfo.OneOf_SpecificInfo, rhs: LicenseInfo.OneOf_SpecificInfo) -> Bool {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch (lhs, rhs) {
      case (.trial, .trial): return {
        guard case .trial(let l) = lhs, case .trial(let r) = rhs else { preconditionFailure() }
        return l == r
      }()
      case (.purchased, .purchased): return {
        guard case .purchased(let l) = lhs, case .purchased(let r) = rhs else { preconditionFailure() }
        return l == r
      }()
      default: return false
      }
    }
  #endif
  }

  init() {}
}

struct TrialLicenseInfo {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var expirationTimestampInSec: Int64 = 0

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}
}

struct PurchasedLicenseInfo {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var licenseKey: String = String()

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}
}

// MARK: - Code below here is support for the SwiftProtobuf runtime.

extension LicenseInfo: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = "LicenseInfo"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "device_uuid"),
    2: .same(proto: "trial"),
    3: .same(proto: "purchased"),
    4: .standard(proto: "extra_info"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularBytesField(value: &self.deviceUuid) }()
      case 2: try {
        var v: TrialLicenseInfo?
        if let current = self.specificInfo {
          try decoder.handleConflictingOneOf()
          if case .trial(let m) = current {v = m}
        }
        try decoder.decodeSingularMessageField(value: &v)
        if let v = v {self.specificInfo = .trial(v)}
      }()
      case 3: try {
        var v: PurchasedLicenseInfo?
        if let current = self.specificInfo {
          try decoder.handleConflictingOneOf()
          if case .purchased(let m) = current {v = m}
        }
        try decoder.decodeSingularMessageField(value: &v)
        if let v = v {self.specificInfo = .purchased(v)}
      }()
      case 4: try { try decoder.decodeSingularBytesField(value: &self.extraInfo) }()
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if !self.deviceUuid.isEmpty {
      try visitor.visitSingularBytesField(value: self.deviceUuid, fieldNumber: 1)
    }
    // The use of inline closures is to circumvent an issue where the compiler
    // allocates stack space for every case branch when no optimizations are
    // enabled. https://github.com/apple/swift-protobuf/issues/1034
    switch self.specificInfo {
    case .trial?: try {
      guard case .trial(let v)? = self.specificInfo else { preconditionFailure() }
      try visitor.visitSingularMessageField(value: v, fieldNumber: 2)
    }()
    case .purchased?: try {
      guard case .purchased(let v)? = self.specificInfo else { preconditionFailure() }
      try visitor.visitSingularMessageField(value: v, fieldNumber: 3)
    }()
    case nil: break
    }
    if !self.extraInfo.isEmpty {
      try visitor.visitSingularBytesField(value: self.extraInfo, fieldNumber: 4)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: LicenseInfo, rhs: LicenseInfo) -> Bool {
    if lhs.deviceUuid != rhs.deviceUuid {return false}
    if lhs.specificInfo != rhs.specificInfo {return false}
    if lhs.extraInfo != rhs.extraInfo {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension TrialLicenseInfo: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = "TrialLicenseInfo"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "expiration_timestamp_in_sec"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularInt64Field(value: &self.expirationTimestampInSec) }()
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if self.expirationTimestampInSec != 0 {
      try visitor.visitSingularInt64Field(value: self.expirationTimestampInSec, fieldNumber: 1)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: TrialLicenseInfo, rhs: TrialLicenseInfo) -> Bool {
    if lhs.expirationTimestampInSec != rhs.expirationTimestampInSec {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension PurchasedLicenseInfo: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = "PurchasedLicenseInfo"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "license_key"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularStringField(value: &self.licenseKey) }()
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if !self.licenseKey.isEmpty {
      try visitor.visitSingularStringField(value: self.licenseKey, fieldNumber: 1)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: PurchasedLicenseInfo, rhs: PurchasedLicenseInfo) -> Bool {
    if lhs.licenseKey != rhs.licenseKey {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}
