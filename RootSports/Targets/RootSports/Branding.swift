//
//  Branding.swift
//  RootSports
//
//  Created by Olena Lysenko on 8/3/17.
//  Copyright © 2017 Ooyala. All rights reserved.
//

import UIKit

class Branding: NSObject {
    private static let ArialBoldMT = "Arial-BoldMT"

    static let errorTitleFont = UIFont.boldSystemFont(ofSize: 18.0)
    static let errorMessageFont = UIFont.systemFont(ofSize: 18.0)
    static let errorButtonFont = UIFont.boldSystemFont(ofSize: 18.0)
    static let errorTitleFontLandscape = UIFont.boldSystemFont(ofSize: 18.0)

    static let channelScheduleTimeFont = UIFont.boldSystemFont(ofSize: 13)
    static let channelScheduleRegionFont = UIFont.boldSystemFont(ofSize: 30)
    static let channelSchedulePickDateButtonFont = UIFont.boldSystemFont(ofSize: 16)

    static let applicationId = "rootsports"
    static let channelScheduleCellProgramOnAirFont = UIFont.boldSystemFont(ofSize: 13)
    static let channelScheduleCellProgramRecordedFont = UIFont(name: ArialBoldMT, size: 13) // and Not OnAir
    static let channelScheduleCellProgramNotRecorddFont = UIFont.boldSystemFont(ofSize: 13) // and Not OnAir
    static let channelScheduleCellProgramContinued = UIFont.italicSystemFont(ofSize: 10)

    static let channelScheduleCellProgramRestricted = UIFont.boldSystemFont(ofSize: 10)
    static let restrictedProgramTextColor = colorFromHex("#353a3b")

    static let splashBackgroundColor = colorFromHex("#161616")

    static let loginNavigationColor = colorFromHex("#ffffff")
    static let loginNavigationTitleColor = colorFromHex("#000000")

    static let loginNavigationTitleFont = UIFont.boldSystemFont(ofSize: 28.0)
    static let loginNavigationSubtitleFont = UIFont.boldSystemFont(ofSize: 16.0)
    static let loginNavigationSubtitleColor = colorFromHex("#000000")

    static let loginBackgroundColor = colorFromHex("#ffffff")

    static let loginNavigationBarItemTint = colorFromHex("#c6c6c6")

    static let mvpdCellBackgroundColor = UIColor.white
    static let mvpdCellBackViewColor = UIColor.white
    static let mvpdCellBorderColor = colorFromHex("262626")
    static let mvpdCellPlaceholderFont = UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.medium)
    static let mvpdCellPlaceholderTextColor = colorFromHex("262626")

    static let playerProgramStatusFont = UIFont.boldSystemFont(ofSize: 8.0)
    static let playerProgramTitleFont = UIFont.boldSystemFont(ofSize: 16.0)

    static let mvpdSearchBackgroundColor = colorFromHex("#ffffff")
    static let mvpdSearchSeparatorColor = colorFromHex("#000000")
    static let mvpdSearchTextColor = colorFromHex("#000000")
    static let mvpdSearchFont = UIFont.systemFont(ofSize: 16.0)
    static let mvpdSearchFieldColor = UIColor.black.withAlphaComponent(0.05)
    static let mvpdSearchTintColor = colorFromHex("#000000")
}
