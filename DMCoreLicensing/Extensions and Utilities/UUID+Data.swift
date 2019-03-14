//
//  UUID+Data.swift
//  DMCoreLicensing
//
//  Created by Darren Mo on 2019-03-13.
//  Copyright © 2019 Darren Mo. All rights reserved.
//

import Foundation

extension UUID {
   var data: Data {
      let bytes = uuid
      return withUnsafePointer(to: bytes) { bytePointer in
         return Data(bytes: UnsafeRawPointer(bytePointer),
                     count: MemoryLayout.size(ofValue: bytes))
      }
   }
}
