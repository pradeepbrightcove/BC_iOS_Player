//
//  Global.swift
//  RootSports
//
//  Created by Oleksandr Haidaiev on 8/15/17.
//  Copyright © 2017 Ooyala. All rights reserved.
//

import UIKit

#if ATT
let isATTApp = true
#else
let isATTApp = false
#endif

#if targetEnvironment(simulator) && os(iOS)
let isIosSimulator = true
#else
let isIosSimulator = false
#endif

let secondsInDay: Int = 86_400 // 60 * 60 * 24

var isIpad: Bool {
    return UIDevice.current.userInterfaceIdiom == .pad
}

struct TimeComponents {
    let amPm: String?
    let digits: String

    var fullTime: String {
        if let ampm = self.amPm {
            return digits + " " + ampm
        } else {
            return digits
        }
    }
}

struct OrientationManager {
    static func supportedInterfaceOrientations(viewController: UIViewController) -> UIInterfaceOrientationMask {
        return isIpad ? .all : .portrait
    }
    static func shouldAutorotate(viewController: UIViewController) -> Bool {
        return isIpad ? true : false
    }
}

let userAgreementKey = "UserAgreementKey"
let userAgreementAcceptSegue = "agree"
let userAgreementDeclineSegue = "decline"

func hasUserAgreement() -> Bool {
    if let value = UserDefaults.standard.value(forKey: userAgreementKey) as? Bool {
        return value
    }

    return false
}

func setUserAgreement(_ userAgreement: Bool) {
    UserDefaults.standard.set(userAgreement, forKey: userAgreementKey)
}
