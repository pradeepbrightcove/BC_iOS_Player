//
//  TestHelper.swift
//  RootSportsTests
//
//  Created by Vladyslav Arseniuk on 2/15/18.
//  Copyright © 2018 Ooyala. All rights reserved.
//

import UIKit

class TestService: NSObject {

    public func parseJson(fromResourceName name: String, ofType type: String) -> Data? {
        let testBundle = Bundle(for: TestService.self)
        let dataPath = testBundle.path(forResource: name, ofType: type)
        let data = try? Data(contentsOf: URL(fileURLWithPath: dataPath!), options: .alwaysMapped)
        return data
    }
}
