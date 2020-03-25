//
//  ConfigModel.swift
//  RootSports
//
//  Created by Olena Lysenko on 9/4/17.
//  Copyright © 2017 Ooyala. All rights reserved.
//

private enum Constants {
    static let pollingDelayKey = "PollingDelay"
    static let zipTimeoutKey = "ZipTimeout"
    static let errorsKey = "Errors"
    static let menuItemsKey = "MenuItems"

    static let menuResourcesKey = "menu_resources"
    static let regionCodeKey = "region_code"

    static let playersKey = "players"
}

class ConfigModel: NSObject, NSCoding {
    var programPollingDelay: TimeInterval = 10.0
    var deviceZipTimeout: TimeInterval = 300.0

    var errors = [ErrorModel]()
    var menuItems = [String: [MenuItemModel]]()

    var blacklistedMvpdIds = [String]()

    var players = [PlayerModel]()

    // default values
    override init() {
        super.init()
    }

    init?(fromDictionary dict: [String: Any]) {
        if let programPollingDelay = dict[ModelConstants.ProgramPollingDelayField] as? NSNumber {
            self.programPollingDelay = programPollingDelay.doubleValue / 1000
        }

        if let deviceZipTimeout = dict[ModelConstants.DeviceZipTimeoutField] as? NSNumber {
            self.deviceZipTimeout = deviceZipTimeout.doubleValue / 1000
        }

        if let blacklistedMvpds = dict[ModelConstants.BlacklistedMvpdsField] as? [String] {
            self.blacklistedMvpdIds = blacklistedMvpds
        }

        if let errorsArray = dict[ModelConstants.ErrorsField] as? [[String: Any]] {
            for errorDict in errorsArray {
                if let error = ErrorModel(fromDictionary: errorDict) {
                    self.errors.append(error)
                }
            }
        }

        if let players = dict[Constants.playersKey] as? [[String: String]] {
            self.players.removeAll()
            for playerDict in players {
                if let player = PlayerModel(fromDictionary: playerDict) {
                    self.players.append(player)
                }
            }
        }

        let menuItemsKey = isATTApp ? "htmlSportsnet" : "htmlRootsports"

        if let menuItems = dict[menuItemsKey] as? [[String: Any]] {
            self.menuItems = [String: [MenuItemModel]]()

            for itemDict in menuItems {
                var itemsArray = [MenuItemModel]()

                if let itemArray = itemDict[Constants.menuResourcesKey] as? [[String: String]] {
                    for dict in itemArray {
                        if let item = MenuItemModel(fromDictionary: dict) {
                            itemsArray.append(item)
                        }
                    }
                }

                if let regionCode = itemDict[Constants.regionCodeKey] as? String {
                    self.menuItems[regionCode] = itemsArray
                }
            }
        }
    }

    func playerIdForMVPD(_ mvpdId: String) -> String? {
        for player in self.players where mvpdId == player.mvpdId {
            return player.playerId
        }
        return nil
    }

    // MARK: NSCoding
    required convenience init?(coder aDecoder: NSCoder) {
        guard let errors = aDecoder.decodeObject(forKey: Constants.errorsKey) as? [ErrorModel],
            let items = aDecoder.decodeObject(forKey: Constants.menuItemsKey)
                        as? [String: [MenuItemModel]] else { return nil }

        self.init()
        self.programPollingDelay = aDecoder.decodeDouble(forKey: Constants.pollingDelayKey)
        self.deviceZipTimeout = aDecoder.decodeDouble(forKey: Constants.zipTimeoutKey)
        self.errors = errors
        self.menuItems = items
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.programPollingDelay, forKey: Constants.pollingDelayKey)
        aCoder.encode(self.deviceZipTimeout, forKey: Constants.zipTimeoutKey)
        aCoder.encode(self.errors, forKey: Constants.errorsKey)
        aCoder.encode(self.menuItems, forKey: Constants.menuItemsKey)
    }
}
