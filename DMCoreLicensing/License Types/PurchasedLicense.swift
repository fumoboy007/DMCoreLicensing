//
//  PurchasedLicense.swift
//  DMCoreLicensing
//
//  Created by Darren Mo on 2019-03-12.
//  Copyright © 2019 Darren Mo. All rights reserved.
//

import Foundation

public struct PurchasedLicense {
   // MARK: - Properties

   public let licenseKey: String

   public let extraInfo: Data

   // MARK: - Initialization

   init(purchasedLicenseInfo: PurchasedLicenseInfo, extraInfo: Data) throws {
      self.licenseKey = purchasedLicenseInfo.licenseKey

      self.extraInfo = extraInfo
   }
}
