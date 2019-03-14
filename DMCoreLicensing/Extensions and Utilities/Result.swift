//
//  Result.swift
//  DMCoreLicensing
//
//  Created by Darren Mo on 2019-03-12.
//  Copyright © 2019 Darren Mo. All rights reserved.
//

public enum Result<Success, Failure: Error> {
   case success(Success)
   case failure(Failure)
}
