//
//  RequestorModel.swift
//  RootSports
//
//  Created by Olena Lysenko on 8/22/17.
//  Copyright © 2017 Ooyala. All rights reserved.
//

class RequestorModel {
    var requestorId: String
    var concurrencyId: String
    var softwareStatement: String

    @available(*, deprecated) var signedRequestorId: String = ""

    init?(fromDictionary dict: [String: Any]) {
        guard let reqId = dict[ModelConstants.RequestorId] as? String,
            let concurrencyId = dict[ModelConstants.ConcurrencyApplicationId] as? String,
            let softwareStatement = dict[ModelConstants.SoftwareStatement] as? String else {
                return nil
        }

        self.requestorId = reqId
        self.concurrencyId = concurrencyId
        self.softwareStatement = softwareStatement
    }
}
