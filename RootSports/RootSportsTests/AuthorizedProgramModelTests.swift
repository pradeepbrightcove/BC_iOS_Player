//
//  AuthorizedProgramModelTests.swift
//  RootSportsTests
//
//  Created by Vladyslav Arseniuk on 2/15/18.
//  Copyright © 2018 Ooyala. All rights reserved.
//

import XCTest
@testable import RootSportsQA

class AuthorizedProgramModelTests: XCTestCase {

    var authProgram: AuthorizedProgramModel?

    override func setUp() {
        super.setUp()
        authProgram = setupAuthProgram(fromResourceName: "AuthorizedProgramModelData", ofType: "json")
    }

    func setupAuthProgram(fromResourceName name: String, ofType type: String) -> AuthorizedProgramModel? {
        guard let authData = TestService().parseJson(fromResourceName: name, ofType: type),
            let programData = TestService().parseJson(fromResourceName: "ProgramModelData", ofType: "json") else {
                return nil
        }

        guard let authProgramDictJson = try? JSONSerialization.jsonObject(with: authData, options: []),
          var authProgramDict = authProgramDictJson as? [String: Any],
          let programDictJson = try? JSONSerialization.jsonObject(with: programData, options: []),
          let programDict = programDictJson as? [String: Any] else { return nil }

        for (key, value) in programDict {
            authProgramDict.updateValue(value, forKey: key)
        }

        let authProgram = AuthorizedProgramModel(fromDictionary: authProgramDict)
        return authProgram
    }

    override func tearDown() {
        authProgram = nil
        super.tearDown()
    }

    func testAuthProgramModelParse() {
        XCTAssertEqual(authProgram?.opt, "opt")
        XCTAssertEqual(authProgram?.apiKey, "apiKey")
        XCTAssertEqual(authProgram?.embedCode, "embedCode")
        XCTAssertEqual(authProgram?.pCode, "providerCode")
    }
}
