//
//  MenuItemModel.swift
//  RootSports
//
//  Created by Sergii Shulga on 9/13/17.
//  Copyright © 2017 Ooyala. All rights reserved.
//

import UIKit

private enum Constants {
    static let keyKey = "key"
    static let typeKey = "type"
    static let nameKey = "name"
    static let dataKey = "data"
    static let urlKey = "url"

}

enum MenuItemType: String {
    case undefined
    case link = "url"
    case html = "html"
}

class MenuItemModel: NSObject, NSCoding {
    var key: String = ""
    var name: String = ""
    var type: MenuItemType = .undefined
    var data: String = ""
    var urlString: String = ""

    // default values
    override init() {
        super.init()
    }

    init?(fromDictionary dict: [String: String]) {
        guard let key = dict[Constants.keyKey], let typeString = dict[Constants.typeKey] else {
            return nil
        }

        self.key = key

        if let name = dict[Constants.nameKey] {
            self.name = name
        }

        if let type = MenuItemType(rawValue: typeString) {
           self.type = type
        }

        if let urlString = dict[Constants.urlKey] {
            self.urlString = urlString
        }

        if let data = dict[Constants.dataKey] {
            self.data = data
        }
    }

    required convenience init?(coder aDecoder: NSCoder) {
        self.init()

        if let key = aDecoder.decodeObject(forKey: Constants.keyKey) as? String {
            self.key = key
        }

        if let name = aDecoder.decodeObject(forKey: Constants.nameKey) as? String {
            self.name = name
        }

        if let typeString = aDecoder.decodeObject(forKey: Constants.typeKey) as? String,
           let type = MenuItemType(rawValue: typeString) {
            self.type = type
        }

        if let url = aDecoder.decodeObject(forKey: Constants.urlKey) as? String {
            self.urlString = url
        }

        if let data = aDecoder.decodeObject(forKey: Constants.dataKey) as? String {
            self.data = data
        }
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.key, forKey: Constants.keyKey)
        aCoder.encode(self.name, forKey: Constants.nameKey)
        aCoder.encode(self.type.rawValue, forKey: Constants.typeKey)
        aCoder.encode(self.urlString, forKey: Constants.urlKey)
        aCoder.encode(self.data, forKey: Constants.dataKey)
    }
}
