//
//  MVPDPickerCollectionViewCell.swift
//  RootSports
//
//  Created by Olena Lysenko on 8/17/17.
//  Copyright © 2017 Ooyala. All rights reserved.
//

import UIKit

private enum MVPDCellConstants {
    static let xOffset = 4.0
    static let yOffset = 8.0
    static let shadowOpacity = 0.42
    static let cornerRadius = 6.0
    static let shadowRadius = 3.0
    static let shadowOffset = CGSize(width: 0, height: 3)
}

class MVPDPickerCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var plceholderView: UIView!

    @IBOutlet weak var placeHolderViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var placeHolderViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var placeHolderViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var placeholderImageToLabelOffsetConstraint: NSLayoutConstraint!

    override func awakeFromNib() {
        backgroundColor = Branding.mvpdCellBackgroundColor
        titleLabel.font = Branding.mvpdCellPlaceholderFont
        titleLabel.textColor = Branding.mvpdCellPlaceholderTextColor

        #if !ATT
            let background = UIView(frame: CGRect(x: MVPDCellConstants.xOffset,
                                                  y: 0.0,
                                                  width: Double(bounds.width) - MVPDCellConstants.xOffset * 2.0,
                                                  height: Double(bounds.height) - MVPDCellConstants.yOffset))
            background.backgroundColor = Branding.mvpdCellBackViewColor
            background.layer.borderWidth = 1.0
            background.layer.borderColor = Branding.mvpdCellBorderColor.cgColor
            background.layer.cornerRadius = CGFloat(MVPDCellConstants.cornerRadius)
            background.layer.shadowColor = Branding.mvpdCellBorderColor.cgColor
            background.layer.shadowRadius = CGFloat(MVPDCellConstants.shadowRadius)
            background.layer.shadowOpacity = Float(MVPDCellConstants.shadowOpacity)
            background.layer.shadowOffset = MVPDCellConstants.shadowOffset

            insertSubview(background, at: 0)

            placeHolderViewTrailingConstraint.constant += CGFloat(MVPDCellConstants.xOffset)
            placeHolderViewLeadingConstraint.constant += CGFloat(MVPDCellConstants.xOffset)
            placeHolderViewBottomConstraint.constant += CGFloat(MVPDCellConstants.yOffset)

            placeholderImageToLabelOffsetConstraint.constant = 3
        #else
            layer.borderWidth = 1.0
            layer.borderColor = Branding.mvpdCellBorderColor.cgColor
        #endif
    }
}
