//
//  AuthorizationProviderTests.swift
//  RootSportsTests
//
//  Created by Vladyslav Arseniuk on 2/22/18.
//  Copyright © 2018 Ooyala. All rights reserved.
//

import XCTest
@testable import RootSportsQA

class AuthorizationProviderTests: XCTestCase {

    var authProvider: AuthorizationProvider?

    class MockNetworkService: AuthorizationNetworkServiceProtocol {
        func startAuth(shortMediaToken: String,
                       billingZip: String,
                       userId: String,
                       completion: @escaping ([String: Any]?, Error?) -> Void) {
            startAuth(shortMediaToken: shortMediaToken, billingZip: billingZip, completion: completion)
        }

        func programMeta(regionCode: String,
                         deviceZip: String,
                         token: String,
                         completion: @escaping NetworkArrayCompletion) {
            switch regionCode {
            case ResponseType.error:
                completion(nil, NSError(domain: "", code: 403, userInfo: nil))

            case ResponseType.unexpected:
                completion(nil, ResponseError.expiredJWT)

            case ResponseType.correct:
                guard let data = TestService().parseJson(fromResourceName: "ProgramMetaData", ofType: "json"),
                    let programMetaData =
                    try? JSONSerialization.jsonObject(with: data,
                                                      options: []) as? [[String: Any]] else {
                                                        return completion(nil, ResponseError.jsonParsing)
                }
                completion(programMetaData, nil)

            default:
                completion(nil, nil)
            }
        }

        func requestorId(completion: @escaping ([String: Any]?, Error?) -> Void) {
            completion(nil, ResponseError.noInternet)
        }

        func startAuth(shortMediaToken: String,
                       billingZip: String,
                       completion: @escaping ([String: Any]?, Error?) -> Void) {
            switch shortMediaToken {
            case ResponseType.error:
                completion(nil, NSError(domain: "", code: 403, userInfo: nil))

            case ResponseType.correct:
                guard let data = TestService().parseJson(fromResourceName: "StartAuthData", ofType: "json"),
                    let startAuthData =
                    try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                        return completion(nil, ResponseError.jsonParsing)
                }
                completion(startAuthData, nil)

            default:
                completion(nil, nil)
            }
        }

        func subscribe(fcmToken: String, authToken: String, completion: @escaping EmptyCompletion) {
            completion()
        }

        func signData(_ dataString: String, token: String) -> (String, Bool) {
            switch dataString {
            case ResponseType.error:
                return ("failed", false)
            case ResponseType.correct:
                return ("success", true)
            default:
                return ("", true)
            }
        }
    }

    class MockLocationManager: AuthorizationLocationProtocol {
        func zipCode(completion: @escaping LocationZipHandler) {
            completion("94102", nil)
        }
    }

    override func setUp() {
        super.setUp()

        authProvider = AuthorizationProvider(networkService: MockNetworkService(),
                                             locationManager: MockLocationManager())
    }

    override func tearDown() {
        authProvider = nil

        super.tearDown()
    }

    func setupAccessEnableManagerForTest() {
        AccessEnablerManager.shared.shortMediaToken = ResponseType.correct
        AccessEnablerManager.shared.encryptedZip = "91293".data(using: .utf8)?.base64EncodedString()
        AccessEnablerManager.shared.subscriberId = "xx"
    }

    func cleanupAccessEnableManagerForTest() {
        AccessEnablerManager.shared.shortMediaToken = nil
        AccessEnablerManager.shared.encryptedZip = nil
        AccessEnablerManager.shared.subscriberId = nil
    }

    func testProgramMetaTest() {
        setupAccessEnableManagerForTest()
        authProvider?.startAuth({ (success: Bool, _: Error?) in
            XCTAssertTrue(success, "Success should be true to continue program meta test")
        })

        AccessEnablerManager.shared.authorizedResources.append("string")
        authProvider?.programMeta(programCode: "FSMA18007C",
                                  channelCode: "RTNW",
                                  regionCode: ResponseType.error,
                                  completion: { (program: [AuthorizedProgram]?, error: Error?) in
            XCTAssertNil(program)
            XCTAssertNotNil(error)
        })
        authProvider?.programMeta(programCode: "FSMA18007C",
                                  channelCode: "RTNW",
                                  regionCode: ResponseType.correct,
                                  completion: { (program: [AuthorizedProgram]?, error: Error?) in
            XCTAssertNil(error)
            XCTAssertNotNil(program)
        })
        AccessEnablerManager.shared.encryptedZip = nil
        authProvider?.programMeta(programCode: "FSMA18007C",
                                  channelCode: "RTNW",
                                  regionCode: ResponseType.unexpected,
                                  completion: { (_: [AuthorizedProgram]?, error: Error?) in
            let isServerLogicalError = error as? ServerLogicalError
            XCTAssertNotNil(isServerLogicalError)
        })
        cleanupAccessEnableManagerForTest()
    }

    func testStartAuth() {
        setupAccessEnableManagerForTest()
        authProvider?.startAuth({ (success: Bool, error: Error?) in
            XCTAssertTrue(success)
            XCTAssertNil(error)
        })

        AccessEnablerManager.shared.shortMediaToken = ResponseType.error
        authProvider?.startAuth({ (success: Bool, error: Error?) in
            XCTAssertFalse(success)
            XCTAssertNotNil(error)
        })
        cleanupAccessEnableManagerForTest()
    }

    func testRequestorId() {
        authProvider?.requestorId({ (_: RequestorModel?, error: Error?) in
            guard let responseError = error as? ResponseError else { return XCTAssertTrue(false) }
            let isResponseError = ResponseError.__derived_enum_equals(responseError, .noInternet)
            XCTAssertTrue(isResponseError)
        })
    }

    func testSignData() {
        let (errorResult, errorSuccess) = (authProvider?.sign(ResponseType.error))!
        XCTAssertFalse(errorSuccess)
        XCTAssertEqual(errorResult, "")

        setupAccessEnableManagerForTest()
        authProvider?.startAuth({ (success: Bool, _: Error?) in
            XCTAssertTrue(success, "Success should be true to continue sign data test")
        })
        let (result, success) = (authProvider?.sign(ResponseType.correct))!
        XCTAssertTrue(success)
        XCTAssertEqual(result, "success")
        cleanupAccessEnableManagerForTest()
    }
}
