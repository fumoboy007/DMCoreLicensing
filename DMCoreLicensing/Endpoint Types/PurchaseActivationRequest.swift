//
//  PurchaseActivationRequest.swift
//  DMCoreLicensing
//
//  Created by Darren Mo on 2019-03-13.
//  Copyright © 2019 Darren Mo. All rights reserved.
//

import Foundation

struct PurchaseActivationRequest: Encodable {
   let computerHardwareUUID: UUID

   let licenseKey: String
}
