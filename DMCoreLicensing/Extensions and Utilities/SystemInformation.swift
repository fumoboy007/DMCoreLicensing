//
//  SystemInformation.swift
//  DMCoreLicensing
//
//  Created by Darren Mo on 2019-03-12.
//  Copyright © 2019 Darren Mo. All rights reserved.
//

import Foundation
import IOKit

struct SystemInformation {
   // MARK: - Initialization

   static let shared = SystemInformation()

   private init() {
      self.hardwareUUID = SystemInformation.fetchHardwareUUID()
   }

   private static func fetchHardwareUUID() -> UUID? {
      let platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault,
                                                       IOServiceMatching("IOPlatformExpertDevice"))
      guard platformExpert != IO_OBJECT_NULL else {
         return nil
      }
      guard let hardwareUUIDString = IORegistryEntryCreateCFProperty(platformExpert, kIOPlatformUUIDKey as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? String else {
         return nil
      }
      guard let hardwareUUID = UUID(uuidString: hardwareUUIDString) else {
         return nil
      }
      return hardwareUUID
   }

   // MARK: - Properties

   let hardwareUUID: UUID?
}
