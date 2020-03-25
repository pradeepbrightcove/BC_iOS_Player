//
//  LiveChannelCollectionViewCell.swift
//  RootSports
//
//  Created by Olena Lysenko on 8/3/17.
//  Copyright © 2017 Ooyala. All rights reserved.
//

import UIKit

class LiveChannelCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var startButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

        statusLabel.font = Branding.playerProgramStatusFont
        titleLabel.font = Branding.playerProgramTitleFont
    }
}
