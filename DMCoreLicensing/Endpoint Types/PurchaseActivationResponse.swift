//
//  PurchaseActivationResponse.swift
//  DMCoreLicensing
//
//  Created by Darren Mo on 2019-03-13.
//  Copyright © 2019 Darren Mo. All rights reserved.
//

import Foundation

struct PurchaseActivationResponse: Decodable {
   let signedLicense: Data?

   let activationError: ActivationError?
}

// MARK: -

extension PurchaseActivationResponse {
   enum ActivationError: RawRepresentable, Error, Decodable {
      // MARK: - Cases

      case licenseKeyNotFound
      case licenseQuotaExceeded

      case unrecognized(String)

      // MARK: - Raw Values

      private static let licenseKeyNotFoundRawValue = "license_key_not_found"
      private static let licenseQuotaExceededRawValue = "license_quota_exceeded"

      init(rawValue: String) {
         switch rawValue {
         case ActivationError.licenseKeyNotFoundRawValue:
            self = .licenseKeyNotFound

         case ActivationError.licenseQuotaExceededRawValue:
            self = .licenseQuotaExceeded

         default:
            self = .unrecognized(rawValue)
         }
      }

      var rawValue: String {
         switch self {
         case .licenseKeyNotFound:
            return ActivationError.licenseKeyNotFoundRawValue

         case .licenseQuotaExceeded:
            return ActivationError.licenseQuotaExceededRawValue

         case .unrecognized(let rawValue):
            return rawValue
         }
      }
   }
}
