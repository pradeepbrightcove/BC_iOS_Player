//
//  Branding.swift
//  RootSports
//
//  Created by Olena Lysenko on 8/3/17.
//  Copyright © 2017 Ooyala. All rights reserved.
//

import UIKit

class Branding: NSObject {
    private static let ATTAleckCdBold    = "ATTAleckCd-Bold"
    private static let ATTAleckCdRegular = "ATTAleckCd-Regular"
    private static let LatoRegular       = "Lato-Regular"
    private static let LatoBold          = "Lato-Bold"

    static let errorTitleFont          = UIFont(name: ATTAleckCdBold, size: 22.0)
    static let errorMessageFont        = UIFont(name: LatoRegular, size: 16.0)
    static let errorButtonFont         = UIFont(name: ATTAleckCdBold, size: 18.0)
    static let errorTitleFontLandscape = UIFont(name: ATTAleckCdBold, size: 18.0)

    static let channelScheduleTimeFont           = UIFont(name: ATTAleckCdBold, size: 13)
    static let channelScheduleRegionFont         = UIFont(name: ATTAleckCdBold, size: 30)
    static let channelSchedulePickDateButtonFont = UIFont(name: LatoBold, size: 16)

    static let applicationId = "sportsnet"
    static let channelScheduleCellProgramOnAirFont = UIFont(name: ATTAleckCdBold, size: 14.0)
    static let channelScheduleCellProgramRecordedFont = UIFont(name: ATTAleckCdRegular, size: 14.0) // and Not OnAir
    static let channelScheduleCellProgramNotRecorddFont = UIFont(name: ATTAleckCdRegular, size: 14.0) // and Not OnAir
    static let channelScheduleCellProgramContinued = UIFont.italicSystemFont(ofSize: 9)

    static let channelScheduleCellProgramRestricted = UIFont(name: ATTAleckCdRegular, size: 10.0)
    static let restrictedProgramTextColor = colorFromHex("#353a3b")

    static let errorBackgroundColor = colorFromHex("#353a3b")

    static let splashBackgroundColor = colorFromHex("#353a3b")

    static let errorTitleColor = colorFromHex("#ffffff")
    static let errorMessageColor = colorFromHex("#ffffff")

    static let loginNavigationColor = colorFromHex("#26a8e6")
    static let loginNavigationTitleColor = colorFromHex("#ffffff")

    static let loginNavigationTitleFont = UIFont(name: "ATTAleckCd-Bold", size: 30.0)
    static let loginNavigationSubtitleFont = UIFont(name: LatoRegular, size: 16.0)
    static let loginNavigationSubtitleColor = colorFromHex("#ffffff")

    static let loginBackgroundColor = UIColor.white

    static let loginNavigationBarItemTint = UIColor.white

    static let mvpdCellBackgroundColor = UIColor.white
    static let mvpdCellBorderColor = colorFromHex("#353a3b")
    static let mvpdCellPlaceholderFont = UIFont(name: ATTAleckCdBold, size: 12)
    static let mvpdCellPlaceholderTextColor = colorFromHex("353a3b")

    static let playerProgramStatusFont = UIFont(name: LatoRegular, size: 8.0)
    static let playerProgramTitleFont = UIFont(name: "Lato-Bold", size: 13.0)

    static let mvpdSearchBackgroundColor = colorFromHex("#353a3b")
    static let mvpdSearchSeparatorColor = colorFromHex("#ffffff")
    static let mvpdSearchTextColor = colorFromHex("#ffffff")
    static let mvpdSearchFont = UIFont(name: ATTAleckCdRegular, size: 16.0)
    static let mvpdSearchFieldColor = UIColor.white.withAlphaComponent(0.05)
    static let mvpdSearchTintColor = colorFromHex("#ffffff").withAlphaComponent(0.5)
}
