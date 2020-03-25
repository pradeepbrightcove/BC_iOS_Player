//
//  NonFatalErrorProvider.swift
//  RootSportsQA
//
//  Created by Vladyslav Arseniuk on 3/5/18.
//  Copyright © 2018 Ooyala. All rights reserved.
//

import UIKit
import Firebase
import Crashlytics

typealias UserInfoHandler = ((_ userInfo: [String: Any]) -> Void)

enum DebugInfoKey {
    static let programMeta       = "ProgramMeta"
    static let selectedChannel   = "Channel"
    static let selectedProgram   = "Program"
    static let ooyalaPlayerError = "PlayerError"
    static let deviceZip         = "DeviceZIP"
}

private enum Constants {
    static let selectedMVPDKey = "SelectedMVPD"
    static let applicationErrorKey = "ApplicationError"
    static let regionKey = "Region"
    static let billingZipKey = "BillingZIP"
    static let authZKey = "AuthZ"
    static let infoKey = "DebugInfo"

    static let errorCodeKey = "ErrorCode"
    static let errorMessageTitleKey = "ErrorMessageTitle"
    static let errorMessageKey = "ErrorMessage"
}

class NonFatalErrorProvider: NSObject {

    static let shared = NonFatalErrorProvider()

    var debugInfo = [String: Any]()

    func recordUserError(error: ServerLogicalError) {
        var userInfo = debugInfo

        let nsError = NSError(domain: "user-alert-error",
                              code: error.rawValue,
                              userInfo: [NSLocalizedDescriptionKey: CoreServices.errorForCode(error).message])

        let errorModel = CoreServices.errorForCode(error)

        var errorDict = [String: Any]()

        errorDict[Constants.errorCodeKey] = errorModel.code
        errorDict[Constants.errorMessageTitleKey] = errorModel.title
        errorDict[Constants.errorMessageKey] = errorModel.message

        userInfo[Constants.applicationErrorKey] = errorDict

        let info = additionalUserInfo()
        userInfo.merge(info, uniquingKeysWith: { (_, new) -> Any in
            return new
        })

        print("Sending Crashlytics log with info: " + userInfo.description)
        print("Error: " + nsError.description)

        Crashlytics.sharedInstance().recordError(nsError, withAdditionalUserInfo: userInfo)

        self.clear()
    }

    func recordUndefinedError(error: Error?, data: Data? = nil, additional: [String: Any]? = nil) {
        guard let error = error else {
            return
        }

        var userInfo = [String: Any]()

        if let additional = additional {
            userInfo = additional
        }

        if let data = data {
            do {
                let jData = try JSONSerialization.jsonObject(with: data)
                if var jsonData = jData as? [String: Any] {
                    if jsonData[ModelConstants.ApiKeyField] != nil {
                        jsonData[ModelConstants.ApiKeyField] = "********"
                    }

                    userInfo[Constants.infoKey] = jsonData
                }

            } catch {
                userInfo[Constants.infoKey] = String(data: data, encoding: .utf8)
            }
        }

        let info = additionalUserInfo()

        userInfo.merge(info, uniquingKeysWith: { (_, new) -> Any in
            return new
        })

        print("Sending Crashlytics log with info: " + info.description)
        print("Error: " + error.localizedDescription)

        Crashlytics.sharedInstance().recordError(error, withAdditionalUserInfo: userInfo)
    }

    private func clear() {
        debugInfo.removeAll()
    }

    private func additionalUserInfo() -> [String: Any] {
        var info = [String: Any]()

        if let mvpdId = AccessEnablerManager.shared.mvpdId {
            info[Constants.selectedMVPDKey] = mvpdId
        }

        if let region = CoreServices.shared.scheduleProvider.regionCode {
            info[Constants.regionKey] = region
        }

        if let billingZip = AccessEnablerManager.shared.encryptedZip {
            info[Constants.billingZipKey] = billingZip
        }

        let authorizedRegions = AccessEnablerManager.shared.authorizedResources
        info[Constants.authZKey] = authorizedRegions

        return info
    }
}
