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

public struct TrialLicense {
   // MARK: - Properties

   public let expirationDate: Date

   /**
    Arbitrary information that the activation server can attach to the license and
    that the application can use to implement its software licensing model.
    */
   public let extraInfo: Data

   // MARK: - Initialization

   init(trialLicenseInfo: TrialLicenseInfo, extraInfo: Data) throws {
      self.expirationDate = Date(timeIntervalSince1970: TimeInterval(trialLicenseInfo.expirationTimestampInSec))

      self.extraInfo = extraInfo
   }

   // MARK: - Checking Expiration

   public func isExpired() -> Bool {
      return expirationDate <= Date()
   }
}
