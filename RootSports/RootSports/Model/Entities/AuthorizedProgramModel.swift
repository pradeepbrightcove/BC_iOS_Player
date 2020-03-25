//
//  AuthorizedProgramModel.swift
//  RootSports
//
//  Created by Sergii Shulga on 8/14/17.
//  Copyright © 2017 Ooyala. All rights reserved.
//

import UIKit

class AuthorizedProgramModel: ProgramModel, AuthorizedProgram {

    var embedCode: String
    var pCode: String
    var opt: String
    var apiKey: String

    override init?(fromDictionary dict: [String: Any]) {

        guard let emCode = dict[ModelConstants.EmbedCodeField] as? String,
            let providerCode = dict[ModelConstants.ProviderCodeField] as? String,
            let opt = dict[ModelConstants.OptField] as? String,
            let apiKey = dict[ModelConstants.ApiKeyField] as? String else {
            return nil
        }

        self.embedCode = emCode
        self.pCode = providerCode
        self.opt = opt
        self.apiKey = apiKey
        // currently we don't use domain at all
//        self.domain = domainCode

        super.init(fromDictionary: dict)
    }
}
