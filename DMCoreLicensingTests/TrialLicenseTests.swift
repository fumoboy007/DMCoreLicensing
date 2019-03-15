//
//  TrialLicenseTests.swift
//  DMCoreLicensingTests
//
//  Created by Darren Mo on 2019-03-14.
//  Copyright © 2019 Darren Mo. All rights reserved.
//

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
