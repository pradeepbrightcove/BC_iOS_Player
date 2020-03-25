//
//  ChannelScheduleTableViewCell.swift
//  RootSports
//
//  Created by Oleksandr Haidaiev on 8/9/17.
//  Copyright © 2017 Ooyala. All rights reserved.
//

import UIKit

protocol ChannelScheduleTableViewCellDelegate: class {
    func channelCellDidSelect(_ cell: ChannelScheduleTableViewCell)
}

struct ChannelScheduleCellData {
    let timeText: NSAttributedString!
    let is24timeFormat: Bool!
    let programText: String!
    let isOnAirNow: Bool!
    let isRecorded: Bool!
    let isStartCell: Bool!
    let isEndCell: Bool!
    let isContinued: Bool!
    let isAllowed: Bool

    init(timeText: NSAttributedString,
         is24timeFormat: Bool,
         programText: String,
         isOnAirNow: Bool,
         isRecorded: Bool,
         isStartCell: Bool,
         isEndCell: Bool,
         isContinued: Bool,
         isAllowed: Bool) {
        self.timeText = timeText
        self.is24timeFormat = is24timeFormat
        self.programText = programText
        self.isOnAirNow = isOnAirNow
        self.isRecorded = isRecorded
        self.isStartCell = isStartCell
        self.isEndCell = isEndCell
        self.isContinued = isContinued
        self.isAllowed = isAllowed
    }
}

private enum CellStates {
    case normal
    case selected
}

private enum Constants {
    static let timeLabelTrailingNormal: CGFloat = 17
    static let timeLabelTrailing24Time: CGFloat = 36
    static let timeLabelTrailingNormaliPad: CGFloat = 30
    static let timeLabelTrailing24TimeiPad: CGFloat = 49

    static let programNameTopConstraintBigger: CGFloat = 32
    static let programNameTopConstraintLower: CGFloat = 18
    static let programNameTrailingConstraintBigger: CGFloat = 54
    static let programNameTrailingConstraintLower: CGFloat = 15
    static let programNameBottomConstraintBigger: CGFloat = 32
    static let programNameBottomConstraintLower: CGFloat = 18
}

private enum StringConstants {
    static let programContinuedTitle: String = "(Continued)"
}

class ChannelScheduleTableViewCell: UITableViewCell {

    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var timeBackground: UIView!

    @IBOutlet weak var programNameLabel: UILabel!
    @IBOutlet weak var programBackground: UIView!
    @IBOutlet weak var liveNowIndicator: UILabel!
    @IBOutlet weak var playIcon: UIImageView!
    @IBOutlet weak var programContinuedLabel: UILabel!

    @IBOutlet weak var separatorVertical: UIView!
    @IBOutlet weak var separatorBottom: UIView!
    @IBOutlet weak var separatorSectionBottom: UIView!

    @IBOutlet weak var timeLabelTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var programNameTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var programNameTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var programNameBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var restrictionsLabel: UILabel!

    public private(set) var cellData: ChannelScheduleCellData?
    weak var delegate: ChannelScheduleTableViewCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        timeLabel.font = Branding.channelScheduleTimeFont

        separatorVertical.backgroundColor = UIColor.Branding.mainDarkSeparator
        separatorBottom.backgroundColor = UIColor.Branding.mainDarkSeparator
        separatorSectionBottom.backgroundColor = UIColor.Branding.mainLowDarkSeparator

        let longPresss = UILongPressGestureRecognizer(target: self, action: #selector(onProgramPress(_:)))
        longPresss.minimumPressDuration = 0
        longPresss.delegate = self
        programBackground.addGestureRecognizer(longPresss)
    }

    // MARK: - Public

    func setUp(cellData cellDataToSetUp: ChannelScheduleCellData) {

        self.cellData = cellDataToSetUp
        if let cellData = self.cellData {

            programContinuedLabel.text = isATTApp ?
                StringConstants.programContinuedTitle.uppercased() : StringConstants.programContinuedTitle
            programContinuedLabel.font = Branding.channelScheduleCellProgramContinued

            restrictionsLabel.font = Branding.channelScheduleCellProgramRestricted
            restrictionsLabel.textColor = Branding.restrictedProgramTextColor

            programNameLabel.textColor = cellData.isAllowed ? UIColor.white : Branding.restrictedProgramTextColor

            timeLabel.attributedText = cellData.timeText
            programNameLabel.text = isATTApp ? cellData.programText.uppercased() : cellData.programText

            if cellData.isOnAirNow {
                programNameLabel.font = Branding.channelScheduleCellProgramOnAirFont
            } else {
                programNameLabel.font = cellData.isRecorded ?
                    Branding.channelScheduleCellProgramRecordedFont :
                    Branding.channelScheduleCellProgramNotRecorddFont
            }

            timeLabel.isHidden = !cellData.isStartCell
            playIcon.isHidden = !(cellData.isOnAirNow && cellData.isAllowed)
            liveNowIndicator.isHidden = !cellData.isOnAirNow || cellData.isRecorded
            separatorBottom.isHidden = cellData.isEndCell
            separatorSectionBottom.isHidden = !cellData.isEndCell
            programContinuedLabel.isHidden = !cellData.isContinued
            restrictionsLabel.isHidden = cellData.isAllowed

            programNameTopConstraint.constant = liveNowIndicator.isHidden ?
                Constants.programNameTopConstraintLower : Constants.programNameTopConstraintBigger
            programNameTrailingConstraint.constant = playIcon.isHidden ?
                Constants.programNameTrailingConstraintLower : Constants.programNameTrailingConstraintBigger
            programNameBottomConstraint.constant = (programContinuedLabel.isHidden &&
                                                    restrictionsLabel.isHidden) ?
                Constants.programNameBottomConstraintLower : Constants.programNameBottomConstraintBigger

            if cellData.is24timeFormat {
                timeLabelTrailingConstraint.constant = isIpad ?
                    Constants.timeLabelTrailing24TimeiPad : Constants.timeLabelTrailing24Time
            } else {
                timeLabelTrailingConstraint.constant = isIpad ?
                    Constants.timeLabelTrailingNormaliPad : Constants.timeLabelTrailingNormal
            }

            timeBackground.backgroundColor = cellData.isOnAirNow ?
                UIColor.Branding.mainLowBright : UIColor.Branding.mainBg

            customizeUI(forState: .normal)

            contentView.updateConstraintsIfNeeded()
        }
    }

    // MARK: - Actions
    @objc private func onProgramPress(_ sender: UILongPressGestureRecognizer) {
        switch sender.state {
        case .began:
            customizeUI(forState: .selected)

        case .ended:
            customizeUI(forState: .normal)

            let tapLocation = sender.location(in: programBackground)
            if programBackground.bounds.contains(tapLocation), let delegate = delegate {
                delegate.channelCellDidSelect(self)
            }

        case .cancelled:
            customizeUI(forState: .normal)

        default: break
        }
    }

    // MARK: - Private

    private func customizeUI(forState state: CellStates) {
        guard let cellData = self.cellData  else {
            return
        }

        if !cellData.isAllowed {
            programBackground.backgroundColor = UIColor.lightGray
            return
        }

        switch state {
        case .normal:
            programBackground.backgroundColor = cellData.isRecorded ?
                UIColor.Branding.mainBg : UIColor.Branding.mainBright
        case.selected:
            programBackground.backgroundColor = cellData.isRecorded ?
                UIColor.Branding.mainBrightBg : UIColor.Branding.mainVeryBright
        }
    }

    // MARK: - UIGestureRecognizerDelegate
    override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                    shouldRecognizeSimultaneouslyWith
        otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
