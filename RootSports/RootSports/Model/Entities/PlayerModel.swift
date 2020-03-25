//
//  PlayerModel.swift
//  RootSports
//
//  Created by Lena on 10/24/18.
//  Copyright © 2018 Ooyala. All rights reserved.
//

import UIKit

class PlayerModel: NSObject {
    var mvpdId: String = ""
    var name: String = ""
    var playerId: String = ""

    init?(fromDictionary dict: [String: String]) {
        if let mvpdId = dict["mvpdId"] {
            self.mvpdId = mvpdId
        }

        if let name = dict["name"] {
            self.name = name
        }

        if let playerId = dict["playerId"] {
            self.playerId = playerId
        }
    }
}

/*
{
    "mvpdId ":"DTV ",
    "name ":"DIRECTV ",
    "playerId ":"b7ef92d5d38543029f28f837d7d5bf6e "
}
*/
