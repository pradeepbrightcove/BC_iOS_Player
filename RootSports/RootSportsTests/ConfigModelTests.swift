//
//  ConfigModelTests.swift
//  RootSportsTests
//
//  Created by Vladyslav Arseniuk on 2/16/18.
//  Copyright © 2018 Ooyala. All rights reserved.
//

import XCTest
@testable import RootSportsQA

class ConfigModelTests: XCTestCase {

    var config: ConfigModel?

    override func setUp() {
        super.setUp()

        config = setupConfigModel(fromResourceName: "ConfigModelData", ofType: "json")
    }

    func setupConfigModel(fromResourceName name: String, ofType type: String) -> ConfigModel? {
        guard let data = TestService().parseJson(fromResourceName: name, ofType: type),
            let configData =
            try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                return nil
        }
        let config = ConfigModel(fromDictionary: configData!)

        return config
    }

    override func tearDown() {
        config = nil

        super.tearDown()
    }

    func testConfigModelParse() {
        XCTAssertEqual(config?.programPollingDelay, 5)
        XCTAssertEqual(config?.deviceZipTimeout, 1920)
        XCTAssertEqual(config?.errors.count, 19)
        XCTAssertEqual(config?.menuItems.values.first?.count, 9)

        XCTAssertNotEqual(config?.programPollingDelay, 10.0)
        XCTAssertNotEqual(config?.deviceZipTimeout, 300.0)
        XCTAssertNotEqual((config?.errors)!, [ErrorModel]())
        XCTAssertNotEqual((config?.menuItems.values.first)!, [MenuItemModel]())
    }

    func testMenuItemModelParse() {
        let menuItem = config?.menuItems.values.first?.first
        XCTAssertNotNil(menuItem)
        XCTAssertNotEqual(menuItem?.key, "")
        XCTAssertNotEqual(menuItem?.name, "")
        XCTAssertNotEqual(menuItem?.type, .undefined)

        if menuItem?.type == .link {
            XCTAssertNotEqual(menuItem?.urlString, "")
        } else {
            XCTAssertNotEqual(menuItem?.data, "")
        }
    }

    func testErrorModelParse() {
        let error = config?.errors[1]
        XCTAssertEqual(error?.message, "The device is rooted. For security reasons the application " +
            "cannot be run from a rooted device.")
        XCTAssertEqual(error?.title, "Unsecure device.")
        XCTAssertEqual(error?.extendedMessage, "")
        XCTAssertEqual(error?.code, 1)
        XCTAssertEqual(error?.iconClass.rawValue, "error__icon-subscription")
    }

    func testConfigCoding() {
        let path = NSTemporaryDirectory() as NSString
        let locToSave = path.appendingPathComponent("teststasks")
        NSKeyedArchiver.archiveRootObject(config!, toFile: locToSave)
        let data = NSKeyedUnarchiver.unarchiveObject(withFile: locToSave) as? ConfigModel

        XCTAssertNotNil(data)
        XCTAssertEqual(data?.programPollingDelay, 5)
        XCTAssertEqual(data?.deviceZipTimeout, 1920)
        XCTAssertEqual(data?.errors.count, 19)
        XCTAssertEqual(data?.menuItems.values.first?.count, 9)
    }
}
