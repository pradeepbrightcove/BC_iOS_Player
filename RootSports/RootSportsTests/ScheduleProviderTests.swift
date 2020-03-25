//
//  ScheduleProviderTests.swift
//  RootSportsTests
//
//  Created by Vladyslav Arseniuk on 2/20/18.
//  Copyright © 2018 Ooyala. All rights reserved.
//

import XCTest
@testable import RootSportsQA

enum ResponseType {
    static let error = "errorResponse"
    static let unexpected = "unexpectedResponse"
    static let correct = "correctResponse"
}

class ScheduleProviderTests: XCTestCase {

    var scheduleProvider: ScheduleProvider?

    class MockNetworkService: ScheduleNetworkServiceProtocol {
        func schedule(region: String,
                      date: Int?,
                      deviceZip: String?,
                      token: String?,
                      completion: @escaping ([String: Any]?, Error?) -> Void) {
        }

        var configResponseType: String?

        func schedule(region: String, date: Int?, completion: @escaping ([String: Any]?, Error?) -> Void) {
            guard let data = TestService().parseJson(fromResourceName: "ScheduleModelData", ofType: "json"),
                var scheduleData =
                try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                    return completion(nil, NSError(domain: "", code: 1, userInfo: nil))
            }

            switch region {
            case ResponseType.error:
                completion(nil, NSError(domain: "", code: 1, userInfo: nil))
            case ResponseType.unexpected:
                scheduleData?.removeValue(forKey: ModelConstants.ProgramsField)
                completion(scheduleData, nil)
            case ResponseType.correct:
                completion(scheduleData, nil)
            default:
                completion(nil, nil)
            }
        }

        func regions(applicationId: String, completion: @escaping ([[String: Any]?]?, Error?) -> Void) {
            guard let data = TestService().parseJson(fromResourceName: "RegionModelData", ofType: "json"),
                let scheduleData =
                try? JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] else {
                    return completion(nil, NSError(domain: "", code: 1, userInfo: nil))
            }

            switch applicationId {
            case ResponseType.error:
                completion(nil, NSError(domain: "", code: 1, userInfo: nil))
            case ResponseType.correct:
                completion(scheduleData, nil)
            default:
                completion(nil, nil)
            }
        }

        func currentProgram(channelCode: String, completion: @escaping NetworkDictionaryCompletion) {
            guard let data = TestService().parseJson(fromResourceName: "CurrentProgramData", ofType: "json"),
                let currentProgramData =
                try? JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] else {
                    return completion(nil, NSError(domain: "", code: 1, userInfo: nil))
            }

            switch channelCode {
            case ResponseType.error:
                completion(nil, NSError(domain: "", code: 1, userInfo: nil))
            case ResponseType.unexpected:
                var modified = currentProgramData?.first
                modified?.removeValue(forKey: ModelConstants.CurrentProgramCodeField)
                completion(modified, nil)
            case ResponseType.correct:
                completion(currentProgramData?.first, nil)
            default:
                completion(nil, nil)
            }
        }

        func config(_ completion: @escaping NetworkDictionaryCompletion) {
                completion(nil, nil)
        }
    }

    override func setUp() {
        super.setUp()

        let locationManager = LocationManager()

        scheduleProvider = ScheduleProvider(networkService: MockNetworkService(), locationManager: locationManager)
    }

    override func tearDown() {
        scheduleProvider = nil

        super.tearDown()
    }

    func testSchedule() {
        let currentDate = Date(timeIntervalSince1970: 1518614596)
        _ = scheduleProvider?.schedule(forDate: currentDate,
                                       region: "correctResponse",
                                       completion: { _, _, error in
            XCTAssertNil(error)
        })
        _ = scheduleProvider?.schedule(forDate: currentDate,
                                       region: "errorResponse",
                                       completion: {  _, _, error in
            XCTAssertNotNil(error)
        })
        _ = scheduleProvider?.schedule(forDate: currentDate,
                                       region: "unexpectedResponse",
                                       completion: {  _, _, error in
            guard let responseError = error as? ResponseError else { return XCTAssertTrue(false) }
            let isUnexpectedFormat = ResponseError.__derived_enum_equals(responseError, .unexpectedFormat)
            XCTAssertTrue(isUnexpectedFormat)
        })
    }

    func testRegions() {
        scheduleProvider?.regions(applicationId: ResponseType.error) { (_ regions: [RegionModel]?, _ error: Error?) in
            XCTAssertNil(regions)
            XCTAssertNotNil(error)
        }
        scheduleProvider?.regions(applicationId: ResponseType.correct) { (_ regions: [RegionModel]?, _ error: Error?) in
            XCTAssertNil(error)
            XCTAssertNotNil(regions)
        }
    }

    func testCurrentProgram() {
        scheduleProvider?.currentProgram(channel: ResponseType.error) { (_ response: String?, _ error: Error?) in
            XCTAssertNil(response)
            XCTAssertNotNil(error)
        }
        scheduleProvider?.currentProgram(channel: ResponseType.unexpected) { (_ response: String?, _ error: Error?) in
            guard let responseError = error as? ResponseError else { return XCTAssertTrue(false) }
            let isUnexpectedFormat = ResponseError.__derived_enum_equals(responseError, .unexpectedFormat)
            XCTAssertTrue(isUnexpectedFormat)
        }
        scheduleProvider?.currentProgram(channel: ResponseType.correct) { (_ response: String?, _ error: Error?) in
            XCTAssertNil(error)
            XCTAssertNotNil(response)
        }
    }

    func testConfig() {
        scheduleProvider?.config({ (_ config: ConfigModel?, _ error: Error?) in
            guard let responseError = error as? ResponseError else { return XCTAssertTrue(false) }
            let isUnexpectedFormat = ResponseError.__derived_enum_equals(responseError, .unexpectedFormat)
            XCTAssertTrue(isUnexpectedFormat, "Must be unexpected format if response and error nil")
        })
    }
}
