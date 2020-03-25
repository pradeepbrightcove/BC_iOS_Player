//
//  RegionModelTests.swift
//  RootSportsTests
//
//  Created by Vladyslav Arseniuk on 2/15/18.
//  Copyright © 2018 Ooyala. All rights reserved.
//

import XCTest
@testable import RootSportsQA

class RegionModelTests: XCTestCase {

    var region: RegionModel?

    override func setUp() {
        super.setUp()

        region = setupRegionModel(fromResourceName: "RegionModelData", ofType: "json")
    }

    func setupRegionModel(fromResourceName name: String, ofType type: String) -> RegionModel? {
        guard let data = TestService().parseJson(fromResourceName: name, ofType: type),
          let regionDataJson = try? JSONSerialization.jsonObject(with: data, options: []),
          let regionData = regionDataJson as? [[String: Any]],
          let firstRegion = regionData.first else { return nil }
        let region = RegionModel(fromDictionary: firstRegion)
        return region
    }

    override func tearDown() {
        region = nil

        super.tearDown()
    }

    func testChannelModelParse() {
        for channel in (region?.channels)! {
            XCTAssertNotEqual(channel.channelName, "UNKNOWN CHANNEL")
            XCTAssertNotEqual(channel.channelCode, "0")
            XCTAssertNotEqual(channel.resourceId, "0")
            XCTAssertNotEqual(channel.channelPriority, .other)
        }

        let channel = region?.channels.first
        XCTAssertEqual(channel?.channelName, "AT&T SportsNet Pittsburgh Alt 2")
        XCTAssertEqual(channel?.channelCode, "ATP2")
        XCTAssertEqual(channel?.resourceId, "ATTSportsPTS")
        XCTAssertEqual(channel?.channelPriority, .alternate)
    }

    func testRegionModelParse() {
        XCTAssertEqual(region?.regionName, "Pittsburgh")
        XCTAssertEqual(region?.regionCode, "PTSB")
        XCTAssertNotEqual(region?.regionName, "UNKNOWN REGION")
        XCTAssertNotEqual(region?.regionCode, "UKNRG")
    }

    func testChannelCodes() {
        let codes = ["ATP2", "ATPT"]
        let wrongCodes = ["ATPT", "ATP2"]
        XCTAssertEqual((region?.channelCodes())!, codes)
        XCTAssertNotEqual((region?.channelCodes())!, wrongCodes)
    }

    func testResourceIds() {
        let ids = ["ATTSportsPTS", "ATTSportsPT"]
        XCTAssertEqual((region?.resourceIds())!, ids)
    }

    func testChannelForCode() {
        XCTAssertEqual(region?.channelForCode("ATP2")?.channelName, region?.channels.first?.channelName)
        XCTAssertNil(region?.channelForCode("RTNW"))
    }

}
