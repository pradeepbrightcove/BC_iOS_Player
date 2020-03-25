//
//  VolumeIndicatorView.swift
//  RootSports
//
//  Created by Olena Lysenko on 8/3/17.
//  Copyright © 2017 Ooyala. All rights reserved.
//

import UIKit

class VolumeIndicatorView: UIView {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initializeSubviews()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        initializeSubviews()
    }

    func initializeSubviews() {
        let viewName = "VolumeIndicatorView"
        guard let view = Bundle.main.loadNibNamed(viewName,
                                                  owner: self,
                                                  options: nil)?[0] as? UIView else { return }
        self.addSubview(view)
        view.frame = self.bounds
    }

    var volume: Float = 0 { // from 0 to 1
        didSet {
            self.updateIndicator()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        let notification = NSNotification.Name(rawValue: "AVSystemController_SystemVolumeDidChangeNotification")
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateIndicator),
                                               name: notification,
                                               object: nil)
        
        
    }

    @IBOutlet weak var indicatorStackView: UIStackView!

    @objc func updateIndicator() {
        
        for view in self.indicatorStackView.subviews {
            if view.tag < Int(self.volume * 10.0) {
                (view as? UIImageView)?.isHighlighted = true
            } else {
                (view as? UIImageView)?.isHighlighted = false
            }
        }
       
    }
}
