//
//  ServicesAndProvidersTests.swift
//  RootSportsTests
//
//  Created by Vladyslav Arseniuk on 2/19/18.
//  Copyright © 2018 Ooyala. All rights reserved.
//

import XCTest
@testable import RootSportsQA

class ServicesAndProvidersTests: XCTestCase {

    func testErrorForCode() {
        let coreService = CoreServices.shared
        coreService.config = ConfigModelTests().setupConfigModel(fromResourceName: "ConfigModelData", ofType: "json")!
        let error = CoreServices.errorForCode(.noPrograms)
        let undefError = CoreServices.errorForCode(.undefined)
        XCTAssertEqual(error.title, "Programs list is empty")
        XCTAssertEqual(undefError.message, "Unknown error occurred. Please refresh page or contact support.")

        coreService.config = ConfigModel()
        let securityError = CoreServices.errorForCode(.appSecurity)
        let defaultError = CoreServices.errorForCode(.noPrograms)
        XCTAssertEqual(securityError.message, "The device is rooted. " +
            "For security reasons the application cannot be run from a rooted device.")
        XCTAssertEqual(defaultError.message, "Unknown error occurred. Please refresh page or contact support.")
    }

    func testProcessLogicError() {
        guard let programMetaData = TestService().parseJson(fromResourceName: "AuthorizedProgramModelData",
                                                            ofType: "json"),
          let programMetaJson = try? JSONSerialization.jsonObject(with: programMetaData, options: []),
          let programMeta = programMetaJson as? [String: Any] else { return XCTFail("JSON nil") }
        let serverError = BaseProvider().processLogicError(programMeta)
        XCTAssertNotNil(serverError)
        XCTAssertEqual(serverError?.rawValue, 13)
        XCTAssertNotEqual(serverError, .undefined)
    }

    func testRegionForChannel() {
        let locationManager = LocationManager()

        let scheduleProvider = ScheduleProvider(networkService: NetworkService(), locationManager: locationManager)
        let regionData = RegionModelTests().setupRegionModel(fromResourceName: "RegionModelData", ofType: "json")
        scheduleProvider.regions = [regionData!]
        let region = scheduleProvider.regionForChannel("ATPT")
        XCTAssertEqual(region?.regionCode, "PTSB")
    }

}
