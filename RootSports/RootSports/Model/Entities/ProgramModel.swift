//
//  ProgramModel.swift
//  RootSports
//
//  Created by Sergii Shulga on 8/9/17.
//  Copyright © 2017 Ooyala. All rights reserved.
//

import Foundation

enum ChannelPriority: Int {
    case primary = 0
    case alternate = 1
    case other = 2
}

class ProgramModel: Program {
    var start: Int
    var duration: Int?
    var channelId: Int?
    var channelCode: String
    var priority: ChannelPriority = .other
    var programId: Int?
    var programCode: String
    var programTitle: String?
    var programTitleBrief: String?
    var resourceId: String
    var live: Bool = false
    var allowed: Bool = false

    var end: Int {
        if let dur = duration {
            return start + dur
        } else {
            return start + 3600 // default is 1h
        }
    }

    init?(fromDictionary dict: [String: Any]) {
        guard let channelCode = dict[ModelConstants.ChannelCodeField] as? String,
            let programCode = dict[ModelConstants.ProgramCodeField] as? String else { return nil }

        if let start = dict[ModelConstants.StartField] as? Int {
            self.start = start
        } else {
            self.start = 0
        }

        self.duration = dict[ModelConstants.DurationSecondsField] as? Int

        self.channelCode = channelCode

        self.programCode = programCode

        self.programTitle = dict[ModelConstants.ProgramTitleField] as? String
        self.programTitleBrief = dict[ModelConstants.ProgramTitleBriefField] as? String

        self.channelId = dict[ModelConstants.ChannelIDField] as? Int

        if let resourceId = dict[ModelConstants.ResourceIDField] as? String {
            self.resourceId = resourceId

        } else if let region = CoreServices.shared.scheduleProvider.regionForChannel(channelCode),
            let channel = region.channelForCode(channelCode) {
                self.resourceId = channel.resourceId

        } else {
            self.resourceId = ""
        }

        self.programId = dict[ModelConstants.ProgramIDField] as? Int

        if let priorityString = dict[ModelConstants.PriorityField] as? String {
            priority = ChannelModel.priority(fromString: priorityString)
        }

        if let isLive = dict[ModelConstants.LiveField] as? Bool {
            live = isLive
        }

        if let isOk = dict[ModelConstants.OKField] as? Bool {
            self.allowed = isOk
        }
    }

    public func isOnAir(serverTimeNow: TimeInterval?) -> Bool {
        guard let serverTimeNow = serverTimeNow else {
            assertionFailure("required parameters not specified")
            return false
        }
        return start <= Int(serverTimeNow) && end >= Int(serverTimeNow)
    }

}

extension ProgramModel: CustomStringConvertible {
    public var description: String {
        let name = programTitle ?? "Empty"
        return "Channel: \(channelCode) Code: \(programCode) Name: \(name) MVPD: \(resourceId)"

    }
}
