//
//  RegionModel.swift
//  RootSports
//
//  Created by Artak on 8/17/17.
//  Copyright © 2017 Ooyala. All rights reserved.
//

import Foundation

class ChannelModel {
    var channelCode: String
    var channelName: String
    var resourceId: String
    var channelPriority: ChannelPriority = .other

    init?(fromDictionary dict: [String: Any]) {
        self.channelName = dict[ModelConstants.ChannelNameField] as? String ?? "UNKNOWN CHANNEL"
        self.channelCode = dict[ModelConstants.ChannelCodeField] as? String ?? "0"
        resourceId = dict[ModelConstants.ResourceIDField] as? String ?? "0"

        if let priorityString = dict[ModelConstants.PriorityField] as? String {
            channelPriority = ChannelModel.priority(fromString: priorityString)
        }
    }

    static func priority(fromString priorityString: String) -> ChannelPriority {
        var priority = ChannelPriority.other

        switch priorityString {
        case ModelConstants.PrimaryValue:
            priority = .primary
        case ModelConstants.AlternateValue:
            priority = .alternate
        default:
            priority = .other
        }

        return priority
    }
}

class RegionModel {
    var regionCode: String
    var regionName: String
    var channels = [ChannelModel]()

    init?(fromDictionary dict: [String: Any]) {

        self.regionName = dict[ModelConstants.RegionNameField] as? String ?? "UNKNOWN REGION"
        self.regionCode = dict[ModelConstants.RegionCodeField] as? String ?? "UKNRG"

        if let channelDicts = dict[ModelConstants.ChannelsField] as? [[String: Any]] {
            for channelDict in channelDicts {
                if let item = ChannelModel(fromDictionary: channelDict) {
                    channels.append(item)
                }
            }
        }
    }

    func channelCodes() -> [String] {
        var channelCodes = [String]()

        for channel in channels {
            channelCodes.append(channel.channelCode)
        }

        return channelCodes
    }

    func resourceIds() -> [String] {
        var resourceIds = [String]()

        for channel in channels {
            resourceIds.append(channel.resourceId)
        }

        return resourceIds
    }

    func channelForCode(_ channelCode: String) -> ChannelModel? {
        for channel in channels where channel.channelCode == channelCode {
            return channel
        }

        return nil
    }
}
