//
//  MVPDPickerViewController.swift
//  RootSports
//
//  Created by Olena Lysenko on 8/15/17.
//  Copyright © 2017 Ooyala. All rights reserved.
//

import UIKit

private enum Constants {
    static let navigationBariPadHeight: CGFloat = 54.0
    // 456 == 150x3 + 2x2 + 1x2 (cell.width / section insets / spacing)
    static let сontentViewWidthIPadLandscape: CGFloat = 456
    static let сontentViewWidthNormal: CGFloat = 305 // 305 == 150x2 + 2x2 + 2x1 (cell.width / section insets / spacing)
    static let preferredContantSizeIPadLandscape = CGSize(width: 645, height: 576)
    static let preferredContantSizeNormal = CGSize(width: 320, height: 576)
    static let title = "LOGIN"
    static let embedCollectionSegue = "embedCollectionSegue"
    static let embedTableSegue = "embedTableSegue"

}

class MVPDPickerViewController: UIViewController {
    var mvpds: [Any]! = []
    var selectionHandler: ((_ mvpd: MVPD) -> Void)?
    var dismissCallback: BoolCompletion?
    private var customNavigationBar: CustomNavigationBar?

//    @IBOutlet weak var contentViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var headerLabel: UILabel! {
        didSet {
            headerLabel.textColor = Branding.loginNavigationSubtitleColor
            headerLabel.font = Branding.loginNavigationSubtitleFont
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        navigationController?.preferredContentSize = UIScreen.isIPadLandscape ?
            Constants.preferredContantSizeIPadLandscape: Constants.preferredContantSizeNormal
        customNavigationBar = navigationController?.navigationBar as? CustomNavigationBar
        if isIpad {
            customNavigationBar?.customHeight = Constants.navigationBariPadHeight
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupLoginView()

//        contentViewWidthConstraint.constant = UIScreen.isIPadLandscape ? Constants.сontentViewWidthIPadLandscape
//                                                                       : Constants.сontentViewWidthNormal
        if isIpad {
            // on iPad this VC is presented modally with presentation style 'Form sheet',
            // by default his super view will have some corner radius, but we need to customith it value
            navigationController?.view.superview?.layer.cornerRadius = isATTApp ? 0 : 4
        }

        self.definesPresentationContext = true

    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return isIpad || isATTApp ? .lightContent : .default
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        if isIpad, UIDevice.current.orientation.isLandscape {
            navigationController?.preferredContentSize = Constants.preferredContantSizeIPadLandscape
//            contentViewWidthConstraint.constant = Constants.сontentViewWidthIPadLandscape
        } else {
            navigationController?.preferredContentSize = Constants.preferredContantSizeNormal
//            contentViewWidthConstraint.constant = Constants.сontentViewWidthNormal
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constants.embedCollectionSegue {
            if let mvpdCollectionVC = segue.destination as? MVPDCollectionViewController {
                mvpdCollectionVC.mvpds = mvpds
                mvpdCollectionVC.selectionHandler = selectionHandler
            }
        } else if segue.identifier == Constants.embedTableSegue {
            if let mvpdCollectionVC = segue.destination as? MVPDTableViewController {
                mvpdCollectionVC.mvpds = mvpds
                mvpdCollectionVC.selectionHandler = selectionHandler
            }
        }
    }

    override func closeButtonPressed(_ sender: Any) {
        if let callback = dismissCallback {
            callback(false)
        }

        dismiss(animated: true, completion: nil)
    }
}

extension UIViewController {
    @objc func closeButtonPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    @objc func setupLoginView() {
        navigationController?.navigationBar.barTintColor = Branding.loginNavigationColor
        navigationController?.navigationBar.tintColor = Branding.loginNavigationTitleColor
        navigationController?.navigationBar.isTranslucent = false
        let attr: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.foregroundColor: Branding.loginNavigationTitleColor,
            NSAttributedString.Key.font: Branding.loginNavigationTitleFont as Any]
        navigationController?.navigationBar.titleTextAttributes = attr

        title = Constants.title

        view.backgroundColor = Branding.loginBackgroundColor

        let closeButton = UIButton(type: .custom)
        closeButton.setImage(UIImage(named: "close-ic"), for: .normal)
        closeButton.addTarget(self, action: #selector(closeButtonPressed(_:)), for: [.touchUpInside])
        closeButton.sizeToFit()

        var containerFrame = closeButton.bounds
        containerFrame.size.height += 10
        let container = UIView(frame: containerFrame)
        container.addSubview(closeButton)

        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: container)
    }
}
