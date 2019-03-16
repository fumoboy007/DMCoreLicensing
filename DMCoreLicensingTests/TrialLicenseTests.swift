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

@testable import DMCoreLicensing

import Foundation
import XCTest

class TrialLicenseTests: XCTestCase {
   func testIsExpired() {
      var trialLicenseInfo = TrialLicenseInfo()
      trialLicenseInfo.expirationTimestampInSec = Int64(Date.distantPast.timeIntervalSince1970)

      let trialLicense = try! TrialLicense(trialLicenseInfo: trialLicenseInfo,
                                           extraInfo: Data())

      XCTAssertTrue(trialLicense.isExpired())
   }

   func testIsNotExpired() {
      var trialLicenseInfo = TrialLicenseInfo()
      trialLicenseInfo.expirationTimestampInSec = Int64(Date.distantFuture.timeIntervalSince1970)

      let trialLicense = try! TrialLicense(trialLicenseInfo: trialLicenseInfo,
                                           extraInfo: Data())

      XCTAssertFalse(trialLicense.isExpired())
   }
}
