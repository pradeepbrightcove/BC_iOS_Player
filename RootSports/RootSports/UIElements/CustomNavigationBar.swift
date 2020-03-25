//
//  CustomNavigationBar.swift
//  RootSports
//
//  Created by Oleksandr Haidaiev on 9/8/17.
//  Copyright © 2017 Ooyala. All rights reserved.
//

import UIKit

class CustomNavigationBar: UINavigationBar {

    public var customHeight: CGFloat?

    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        let defaultRect = super.sizeThatFits(size)

        if let customHeight = customHeight {
            return CGSize(width: defaultRect.width, height: customHeight)
        } else {
            return defaultRect
        }
    }
}
