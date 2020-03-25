//
//  ChooseRegionTableCell.swift
//  RootSports
//
//  Created by Artak on 8/7/17.
//  Copyright © 2017 Ooyala. All rights reserved.
//

import UIKit

class ChooseRegionTableCell: UITableViewCell {

    @IBOutlet weak var regionNameLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
// till iOS 10 on iPads cell.backgroundColor will ignore value from storyboard and will be white by default
        backgroundColor = .clear
    }
}
