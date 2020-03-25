//
//  BaseNavigationBar.swift
//  RootSports
//
//  Created by Oleksandr Haidaiev on 8/18/17.
//  Copyright © 2017 Ooyala. All rights reserved.
//

import Foundation

class BaseNavigationController: UINavigationController {

    // WARNING: this method not called in Simulator on: iPad Air 2 iOS 9.3/10.3.1,
    // iPad Pro 12.9 iOS 9.3, iPad Pro 10.5 iOS 10.3.1, if in General project settings: all
    // orientations are active for iPad and 'Requires full screen' checkmark is unselected
    // but on Device iPad 2 iOS 9.3.5 is OK
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return OrientationManager.supportedInterfaceOrientations(viewController: self)
    }

    // same problem
    override open var shouldAutorotate: Bool {
        return OrientationManager.shouldAutorotate(viewController: self)
    }
}
