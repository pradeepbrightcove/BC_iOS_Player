//
//  ScheduleNodeModel.swift
//  RootSports
//
//  Created by Sergii Shulga on 8/9/17.
//  Copyright © 2017 Ooyala. All rights reserved.
//

import Foundation

class ScheduleNodeModel {
    var start: Int
    var end: Int
    var programs: [ProgramModel]

    var uniqueProgramsCount: Int {
        var count = programs.count

        for program in programs {
            for otherProgram in programs where program.channelCode != otherProgram.channelCode &&
                                               program.priority.rawValue > otherProgram.priority.rawValue &&
                                               program.programCode == otherProgram.programCode &&
                                               program.start == otherProgram.start {
                count -= 1
            }
        }

        return count
    }

    /// Methods cerates ScheduleNodeModel with list of ProgramModel
    ///
    /// - Parameter programs: list of ProgramModel. All programs should have same start time
    init(programs: [ProgramModel]) {

        assert(programs.count > 0)
        self.programs = (programs.sorted { $0.priority.rawValue < $1.priority.rawValue })
                        .sorted(by: { (program1, program2) -> Bool in

            if program1.programCode == program2.programCode, program1.allowed != program2.allowed {
                return program1.allowed
            }

            return false
        })

        if let program = self.programs.first {
            self.start = program.start
            self.end = program.end
        } else {
            self.start = 0
            self.end = 0
        }
    }

    func duplicatePrograms(_ original: ProgramModel) -> [ProgramModel]? {
        var duplicates = [ProgramModel]()

        for program in programs where original.channelCode != program.channelCode &&
                                      original.programCode == program.programCode &&
                                      original.start == program.start {
            duplicates.append(program)
        }

        if duplicates.count > 0 {
            return duplicates
        }

        return nil
    }
}

extension ScheduleNodeModel: Equatable {
    static func == (lhs: ScheduleNodeModel, rhs: ScheduleNodeModel) -> Bool {
        return lhs.start == rhs.start
    }
}

extension ScheduleNodeModel: CustomStringConvertible {
    public var description: String {
        var result = "ScheduleNodeModel: Date - \(start), Programs: [\n"

        for program in programs {
            result.append(" \(program)\n")
        }

        result.append("]")

        return result
    }
}
