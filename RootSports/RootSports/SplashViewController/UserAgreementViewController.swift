//
//  UserAgreementViewController.swift
//  RootSports
//
//  Created by Olena Lysenko on 12/4/17.
//  Copyright © 2017 Ooyala. All rights reserved.
//

import UIKit

class UserAgreementViewController: MenuWebViewController {

    var agreeAction: EmptyCompletion?
    var declineAction: EmptyCompletion?

    @IBOutlet weak var agreeButton: UIButton!
    @IBOutlet weak var declineButton: UIButton!

    @IBOutlet weak var navigationBar: UINavigationBar!

    @IBAction func declineButtonPressed(_ sender: Any) {
        if let action = declineAction {
            action()
        }
    }

    @IBAction func agreeButtonPressed(_ sender: Any) {
        setUserAgreement(true)

        if let action = agreeAction {
            action()
        }
    }

    @IBOutlet weak var backView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationBar.barTintColor = Branding.loginNavigationColor
        navigationBar.tintColor = Branding.loginNavigationTitleColor
        navigationBar.isTranslucent = false
        navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: Branding.loginNavigationTitleColor,
                                             NSAttributedString.Key.font: Branding.errorTitleFont as Any]

        view.backgroundColor = UIColor.Branding.mainBg
        backView.backgroundColor = Branding.loginNavigationColor

        agreeButton.backgroundColor = UIColor.Branding.mainBright
        declineButton.backgroundColor = UIColor.Branding.mainLowBright
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return OrientationManager.supportedInterfaceOrientations(viewController: self)
    }

    override open var shouldAutorotate: Bool {
        return OrientationManager.shouldAutorotate(viewController: self)
    }
}
