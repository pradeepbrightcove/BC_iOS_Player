//
//  ProgramModelTests.swift
//  RootSportsTests
//
//  Created by Vladyslav Arseniuk on 2/14/18.
//  Copyright © 2018 Ooyala. All rights reserved.
//

import XCTest
@testable import RootSportsQA

class ProgramModelTests: XCTestCase {

    var program: ProgramModel?
    var failedProgram: ProgramModel?

    override func setUp() {
        super.setUp()
        program = setupProgramData(fromResourceName: "ProgramModelData", ofType: "json")
        failedProgram = setupProgramData(fromResourceName: "WrongProgramModelData", ofType: "json")
    }

    func setupProgramData(fromResourceName name: String, ofType type: String) -> ProgramModel? {
        guard let data = TestService().parseJson(fromResourceName: name, ofType: type),
            let programDataJson = try? JSONSerialization.jsonObject(with: data, options: []),
            let programData = programDataJson as? [String: Any] else {
                return nil
        }
        let program = ProgramModel(fromDictionary: programData)
        return program
    }

    override func tearDown() {
        program = nil
        failedProgram = nil
        super.tearDown()
    }

    func testProgramModelInit() {
        XCTAssertNotNil(program!)
    }

    func testOnAirProgram() {
        XCTAssertTrue((program?.isOnAir(serverTimeNow: 1518523220))!, "Program should be on air")
        XCTAssertFalse((program?.isOnAir(serverTimeNow: 1518529000))!, "Program shouldn't be on air")
        XCTAssertFalse((failedProgram?.isOnAir(serverTimeNow: 1518523220))!, "Can't be on air with negative duration")
    }

    func testDurationIsNegative() {
        XCTAssertEqual(failedProgram?.duration, -3600)
    }

    func testProgramDescription() {
        XCTAssertEqual(program?.description,
                       "Channel: RTNW Code: FSMA18007C Name: Fight Sports: MMA '18 MVPD: ROOTSportsNW")
        XCTAssertNotEqual(program?.description, failedProgram?.description)
    }

    func testProgramStartTimeNotZero() {
        XCTAssertNotEqual(program?.start, 0)
    }

    func testProgramPriorityNotNil() {
        XCTAssertNotNil(program?.priority)
    }

    func testProgramResourceIdNotNil() {
        XCTAssertNotNil(program?.resourceId)
    }

    func testProgramModelParse() {
        XCTAssertTrue(program?.duration == 3600)
        XCTAssertNil(program?.channelId)
        XCTAssertTrue(program?.channelCode == "RTNW")
        XCTAssertNil(program?.programId)
        XCTAssertTrue(program?.programCode == "FSMA18007C")
        XCTAssertTrue(program?.programTitle == "Fight Sports: MMA '18")
        XCTAssertTrue(program?.programTitleBrief == "Fight Sports: MMA - 7")
        XCTAssertTrue(program?.live == false)
        XCTAssertTrue(program?.end == 1518526800)
    }
}
