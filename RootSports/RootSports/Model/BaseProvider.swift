//
//  BaseProvider.swift
//  RootSports
//
//  Created by Sergii Shulga on 8/22/17.
//  Copyright © 2017 Ooyala. All rights reserved.
//

import Foundation

class BaseProvider {
    func processLogicError(_ dictionary: [String: Any]) -> ServerLogicalError? {
        guard let status = dictionary[ModelConstants.OKField] as? Bool else {
            return nil
        }

        if !status {
            if let errorCode = dictionary[ModelConstants.ErrorCodeField] as? Int,
                let logicalError = ServerLogicalError(rawValue: errorCode) {
                return logicalError
            } else {
                return ServerLogicalError.undefined
            }
        } else {
            return nil
        }
    }
}
