//
//  ScheduleNodeModelTests.swift
//  RootSportsTests
//
//  Created by Vladyslav Arseniuk on 2/15/18.
//  Copyright © 2018 Ooyala. All rights reserved.
//

import XCTest
@testable import RootSportsQA

class ScheduleNodeModelTests: XCTestCase {

    var scheduleNode: ScheduleNodeModel?

    override func setUp() {
        super.setUp()
        scheduleNode = setupScheduleNode(fromResourceName: "ScheduleModelData", ofType: "json")
    }

    func setupScheduleNode(fromResourceName name: String, ofType type: String) -> ScheduleNodeModel? {
        guard let data = TestService().parseJson(fromResourceName: name, ofType: type),
            let scheduleDataJson =  try? JSONSerialization.jsonObject(with: data, options: []),
            let scheduleData = scheduleDataJson as? [String: Any],
            let programsData = scheduleData[ModelConstants.ProgramsField] as? [[String: Any]] else { return nil }
        var programs = [ProgramModel]()

        for program in programsData {
            programs.append(ProgramModel(fromDictionary: program)!)
        }

        let scheduleNode = ScheduleNodeModel(programs: programs)
        return scheduleNode
    }

    override func tearDown() {
        scheduleNode = nil
        super.tearDown()
    }

    func testScheduleNodeModelParse() {
        XCTAssertEqual(scheduleNode?.start, 1518606000)
        XCTAssertEqual(scheduleNode?.end, 1518616800)
    }

    func testNodeDescription() {
        XCTAssertEqual(scheduleNode?.description, "ScheduleNodeModel: Date - 1518606000, Programs: [" +
            "\n Channel: RTNW Code: UFCR16012N Name: UFC 202: Diaz vs McGregor II - 12 MVPD: ROOTSportsNW" +
            "\n Channel: ATUT Code: JAZZ17063Z Name: Suns at Jazz (2/14/18) - 63 MVPD: ROOTSportsNW" +
            "\n Channel: ATLV Code: VGKN17056C Name: Blackhawks at Golden Knights (2/13/18) - 56 MVPD: ROOTSportsNW\n]")
    }

    func testProgramStartTime() {
        let startTime = scheduleNode?.start

        for program in (scheduleNode?.programs)! {
            XCTAssertEqual(startTime, program.start, "All programs should have same start time")
        }
    }
}
