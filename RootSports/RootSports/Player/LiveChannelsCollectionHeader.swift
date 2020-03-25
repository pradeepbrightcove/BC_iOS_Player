//
//  LiveChannelsCollectionHeader.swift
//  RootSports
//
//  Created by Artak on 9/4/17.
//  Copyright © 2017 Ooyala. All rights reserved.
//

import UIKit

protocol LiveChannelsCollectionHeaderDelegate: class {
    func liveChannelsCollectionHeaderTapped(_ cell: LiveChannelsCollectionHeader)
}

class LiveChannelsCollectionHeader: UICollectionReusableView {

    weak var delegate: LiveChannelsCollectionHeaderDelegate?

    @IBAction func scheduleButtonAction(_ sender: UIButton) {
        if let delegate = delegate {
            delegate.liveChannelsCollectionHeaderTapped(self)
        }
        
      
        
    }
}


