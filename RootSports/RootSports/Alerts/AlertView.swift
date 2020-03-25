//
//  AlertView.swift
//  RootSports
//
//  Created by Olena Lysenko on 8/10/17.
//  Copyright © 2017 Ooyala. All rights reserved.
//

import UIKit

enum AlertViewType {
    case generalError
    case subscriptionInactive
    case locationUnavailable
}

class AlertAction {
    var title: String
    var action: (() -> Void)

    init(title: String, action:  @escaping (() -> Void)) {
        self.title = title
        self.action = action
    }
}

// MARK: Convenience calls
func showAlertView(title: String?,
                   message: String?,
                   type: AlertViewType = .generalError,
                   isPlayer: Bool = false,
                   alertAction: AlertAction? = nil,
                   alertError: Error? = nil,
                   completion: ((Bool) -> Void)? = nil) {
    AlertViewManager.show(title: title,
                          message: message,
                          type: type,
                          isPlayer: isPlayer,
                          alertAction: alertAction,
                          alertError: alertError,
                          completion: completion)
}

func showAlertForError(code: ServerLogicalError,
                       params: [CVarArg]? = nil,
                       extendedMessage: Bool = false,
                       isPlayer: Bool,
                       alertAction: AlertAction? = nil,
                       completion: BoolCompletion? = nil) {
    let error = CoreServices.errorForCode(code)
    var message = ""

    if let params = params {
        message = String(format: error.message, arguments: params)
    } else {
        message = error.message
    }

    if extendedMessage {
        message += " " + error.extendedMessage
    }

    var type = AlertViewType.generalError

    switch error.iconClass {
    case .location:
        type = AlertViewType.locationUnavailable
    case .subscription:
        type = AlertViewType.subscriptionInactive
    default:
        break
    }

    showAlertView(title: error.title,
                  message: message,
                  type: type,
                  isPlayer: isPlayer,
                  alertAction: alertAction,
                  alertError: code,
                  completion: completion)
}

class AlertViewManager: NSObject {
    static let sharedInstance = AlertViewManager()

    var completionHandler: ((Bool) -> Void)?
    var alertAction: AlertAction?
    var alertError: Error?

    var isPresented = false
    var isPlayer: Bool = false

    static func show(title: String?,
                     message: String?,
                     type: AlertViewType,
                     isPlayer: Bool,
                     alertAction: AlertAction?,
                     alertError: Error? = nil,
                     completion: ((Bool) -> Void)?) {
        if sharedInstance.isPresented { return }

        DispatchQueue.main.async {
            AlertViewManager.sharedInstance.isPlayer = isPlayer
            AlertViewManager.sharedInstance.alertAction = alertAction
            AlertViewManager.sharedInstance.show(title: title, message: message, type: type)
            AlertViewManager.sharedInstance.completionHandler = completion
            AlertViewManager.sharedInstance.alertError = alertError
        }
    }

    static func hide(isAction: Bool) {
        if !sharedInstance.isPresented { return }

        DispatchQueue.main.async {
            AlertViewManager.sharedInstance.hide(isAction: isAction)
        }
    }

    // MARK: Private
    static let windowBackgroundColor = UIColor.black.withAlphaComponent(0.6)

    private var window: UIWindow = {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.windowLevel = UIWindow.Level.alert + 1
        window.backgroundColor = windowBackgroundColor
        return window
    }()

    private func show(title: String?, message: String?, type: AlertViewType) {
        isPresented = true

        window.makeKeyAndVisible()

        let viewController = AlertViewController(nibName: "AlertView", bundle: Bundle.main)

        window.rootViewController = viewController

        viewController.alertTitle = title
        viewController.alertMessage = message

        viewController.view.frame = window.bounds

        switch type {
        case .generalError:
            viewController.iconName = "denied-general"
        case .locationUnavailable:
            viewController.iconName = "denied-location"
        case .subscriptionInactive:
            viewController.iconName = "denied-from-subscription"
        }

        if let alertAction = alertAction {
            viewController.actionButtonTitle = alertAction.title
        } else {
            viewController.actionButtonTitle = nil
        }

        viewController.view.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
        window.backgroundColor = UIColor.clear

        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: {
            viewController.view.transform = CGAffineTransform.identity
            self.window.backgroundColor = AlertViewManager.windowBackgroundColor
        })

        if let error = AlertViewManager.sharedInstance.alertError as? ServerLogicalError {
            NonFatalErrorProvider.shared.recordUserError(error: error)
        }
    }

    private func hide(isAction: Bool) {
        isPresented = false

        if let viewController = window.rootViewController {
            viewController.view.transform = CGAffineTransform.identity
        }

        window.backgroundColor = AlertViewManager.windowBackgroundColor

        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: {
            if let viewController = self.window.rootViewController {
                viewController.view.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
            }
            self.window.backgroundColor = UIColor.clear
        }, completion: { _ in
            self.window.isHidden = true

            if let alertAction = self.alertAction, isAction {
                alertAction.action()
            }

            if let handler = self.completionHandler {
                handler(isAction)
            }

            self.window.rootViewController = nil
        })
    }
}

class AlertViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBOutlet weak var alertViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var actionButtonHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var alertButtonMinHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var topViewHeightContraint: NSLayoutConstraint!

    @IBOutlet weak var alertView: UIView! {
        didSet {
            alertView.backgroundColor = UIColor.Branding.errorBackground
        }
    }

    @IBOutlet weak var topView: UIView! {
        didSet {
            topView.backgroundColor = UIColor.Branding.errorButton
        }
    }

    @IBOutlet weak var titleLabel: UILabel! {
        didSet {
            titleLabel.textColor = UIColor.Branding.errorTitle
            titleLabel.font = Branding.errorTitleFont
        }
    }

    @IBOutlet weak var iconView: UIImageView! {
        didSet {
            iconView.image = UIImage(named: iconName)
        }
    }

    @IBOutlet weak var messageLabel: UILabel! {
        didSet {
            messageLabel.textColor = UIColor.Branding.errorMessage
            messageLabel.font = Branding.errorMessageFont

            messageLabel.text = alertMessage
        }
    }

    @IBOutlet weak var actionButton: UIButton! {
        didSet {
            guard let actionButtonTitle = actionButtonTitle else { return }

            let dict: [NSAttributedString.Key: Any] = [
                .underlineStyle: 0,
                .font: Branding.errorButtonFont as Any,
                .foregroundColor: UIColor.white
            ]

            let attString = NSMutableAttributedString()
            attString.append(NSAttributedString(string: actionButtonTitle, attributes: dict))
            actionButton.setAttributedTitle(attString, for: .normal)
            actionButton.backgroundColor = UIColor.Branding.errorButton
        }
    }

    @IBOutlet weak var closeButton: UIButton! {
        didSet {
            if !isATTApp {
                closeButton.setImage(closeButton.currentImage?.withRenderingMode(.alwaysTemplate), for: .normal)
                closeButton.tintColor = UIColor.white
            }
        }
    }

    @IBOutlet weak var sendInfoButton: UIButton! {
        didSet {
            guard let buttonTitle = sendInfoButton.title(for: .normal) else { return }

            let dict: [NSAttributedString.Key: Any] = [.font: Branding.errorButtonFont as Any,
                                                       .foregroundColor: UIColor.white]

            let attString = NSMutableAttributedString()
            attString.append(NSAttributedString(string: buttonTitle, attributes: dict))
            sendInfoButton.setAttributedTitle(attString, for: .normal)

            sendInfoButton.backgroundColor = UIColor.Branding.debugErrorButton
        }
    }

    var alertTitle: String? {
        didSet {
            #if ATT
                alertTitle = alertTitle?.uppercased()
            #endif

            self.titleLabel?.text = alertTitle
        }
    }

    var alertMessage: String? {
        didSet {
            self.messageLabel?.text = alertMessage
        }
    }

    var actionButtonTitle: String? {
        didSet {
            guard actionButtonHeightConstraint != nil else {
                return
            }
            if actionButtonTitle == nil {
                actionButtonHeightConstraint.constant = 0
//                alertButtonMinHeightConstraint.isActive = false
            } else {
                actionButtonHeightConstraint.constant = 72
//                alertButtonMinHeightConstraint.isActive = true

                #if ATT
                    actionButtonTitle = actionButtonTitle?.uppercased()
                #endif

                let dict: [NSAttributedString.Key: Any] = [.underlineStyle: 0,
                                                           .font: Branding.errorButtonFont as Any,
                                                           .foregroundColor: UIColor.white]
                let attString = NSMutableAttributedString()
                attString.append(NSAttributedString(string: actionButtonTitle!, attributes: dict))
                actionButton.setAttributedTitle(attString, for: .normal)
                actionButton.backgroundColor = UIColor.Branding.errorButton
            }
        }
    }

    var iconName: String = "denied-general" {
        didSet {
            self.iconView?.image = UIImage(named: iconName)
        }
    }

    @IBAction func closeButtonAction(_ sender: Any) {
        AlertViewManager.hide(isAction: false)
    }

    @IBAction func actionButtonPressed(_ sender: UIButton) {
        AlertViewManager.hide(isAction: true)
    }

    @IBAction func sendInfoButtonPressed(_ sender: UIButton) {
        let alert = UIAlertController(title: "Your debug information was sent to developers",
                                      message: "Thank you for helping us to improve the application!",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)

        if let error = AlertViewManager.sharedInstance.alertError as? ServerLogicalError {
            NonFatalErrorProvider.shared.recordUserError(error: error)
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if isIpad {
            return .all
        }
        if AlertViewManager.sharedInstance.isPlayer {
            return .landscape
        }
        return .portrait
    }
    
    

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        if isIpad {
            if  UIScreen.main.bounds.size.width > UIScreen.main.bounds.size.height {
                alertViewWidthConstraint.constant = 440
            } else {
                alertViewWidthConstraint.constant = isATTApp ? 320 : 330
            }
        } else {
            if AlertViewManager.sharedInstance.isPlayer {
                alertViewWidthConstraint.constant = 440
                titleLabel.font = Branding.errorTitleFontLandscape
            } else {
                alertViewWidthConstraint.constant = isATTApp ? 320 : 330
                titleLabel.font = Branding.errorTitleFont
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        perform(#selector(refresh), with: nil, afterDelay: 0.1)
    }

    @objc func refresh() {
        titleLabel.sizeToFit()
        titleLabel.setNeedsLayout()
        alertView.setNeedsDisplay()
    }
}
