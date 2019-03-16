//
//  TrialLicense.swift
//  DMCoreLicensing
//
//  Created by Darren Mo on 2019-03-12.
//  Copyright © 2019 Darren Mo. All rights reserved.
//

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
