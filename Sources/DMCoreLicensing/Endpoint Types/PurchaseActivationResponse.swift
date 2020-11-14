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

struct PurchaseActivationResponse: Decodable {
   let signedLicense: Data?

   let activationError: ActivationError?
}

// MARK: -

extension PurchaseActivationResponse {
   enum ActivationError: RawRepresentable, Error, Decodable {
      // MARK: - Cases

      case licenseKeyNotFound
      case deviceQuotaExceeded

      case unrecognized(String)

      // MARK: - Raw Values

      private static let licenseKeyNotFoundRawValue = "license_key_not_found"
      private static let deviceQuotaExceededRawValue = "device_quota_exceeded"

      init(rawValue: String) {
         switch rawValue {
         case ActivationError.licenseKeyNotFoundRawValue:
            self = .licenseKeyNotFound

         case ActivationError.deviceQuotaExceededRawValue:
            self = .deviceQuotaExceeded

         default:
            self = .unrecognized(rawValue)
         }
      }

      var rawValue: String {
         switch self {
         case .licenseKeyNotFound:
            return ActivationError.licenseKeyNotFoundRawValue

         case .deviceQuotaExceeded:
            return ActivationError.deviceQuotaExceededRawValue

         case .unrecognized(let rawValue):
            return rawValue
         }
      }
   }
}
