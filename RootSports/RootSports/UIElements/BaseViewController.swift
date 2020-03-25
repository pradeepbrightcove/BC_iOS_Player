//
//  BaseViewController.swift
//  RootSports
//
//  Created by Sergii Shulga on 8/23/17.
//  Copyright © 2017 Ooyala. All rights reserved.
//

import UIKit

typealias EmptyCompletion = () -> Void
typealias BoolCompletion = (_ isAction: Bool) -> Void

enum ContextKey {
    static let mvpd = "mvpd_name"
    static let alternate = "alternate_program_name"
    static let programs = "available_programs"
}

enum ErrorConstants {
    static let errorTitle = "Error"
    static let mvpdName = "MVPD"
    static let alternateProgram = "alternate program"

    static let undefinedError = "Unknown error occurred. Please refresh page or contact support."
    static let unexpectedResponse = "Unexpected response format"
    static let noInternet = "Server is not reachable. Please check your Internet connection."
    static let invalidGeocode = "App can't determine you current ZIP code"
    static let locationManagerFail = "Could not get your location. Please try again."
    static let locationServicesTurnedOff = "Location services are turned off. To get access, " +
                                            "please allow to detect your location."
}

class BaseViewController: UIViewController {

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    func isPlayer() -> Bool {
        return false
    }

    func showAlert(title: String?,
                   message: String?,
                   type: AlertViewType = .generalError,
                   alertAction: AlertAction? = nil,
                   completion: ((Bool) -> Void)? = nil) {
        showAlertView(title: title,
                      message: message,
                      type: type,
                      isPlayer: isPlayer(),
                      alertAction: alertAction,
                      completion: completion)
    }

    func showErrorFor(code: ServerLogicalError,
                      params: [CVarArg]? = nil,
                      extendedMessage: Bool = false,
                      alertAction: AlertAction? = nil,
                      completion: BoolCompletion? = nil) {

        showAlertForError(code: code,
                          params: params,
                          extendedMessage: extendedMessage,
                          isPlayer: isPlayer(),
                          alertAction: alertAction,
                          completion: completion)
    }

    // MARK: common methods
    func updateUI() {
        // should be implemented in subclasses
    }

    // MARK: main error handling function
    final func handle(error: Error,
                      context: AnyObject? = nil,
                      action: EmptyCompletion? = nil,
                      completion: BoolCompletion? = nil) {

        if let error = error as? ResponseError {
            handle(responseError: error)
        } else if let error = error as? ServerLogicalError {
            handle(serverLogicalError: error, context: context, action: action, completion: completion)
        } else if let error = error as? LocationError {
            handle(locationError: error)
        } else {
            var userInfo = [String: Any]()

            if let context = context as? [String: Any] {
                userInfo[ModelConstants.ChannelCodeField] = context[ModelConstants.ChannelCodeField]
                userInfo[ModelConstants.ProgramCodeField] = context[ModelConstants.ProgramCodeField]
            }

            NonFatalErrorProvider.shared.recordUndefinedError(error: error, additional: userInfo)
            handle(otherError: error)
        }
    }

    // MARK: Handle error by types
    private func handle(responseError: ResponseError) {
        switch responseError {
        case .noInternet:
            showAlert(title: ErrorConstants.errorTitle, message: ErrorConstants.noInternet)
        default:
            showErrorFor(code: ServerLogicalError.undefined)
        }
    }

    private func handle(serverLogicalError: ServerLogicalError,
                        context: AnyObject? = nil,
                        action: EmptyCompletion? = nil,
                        completion: BoolCompletion? = nil) {
        switch serverLogicalError {
        case .appSecurity:
            print("Unsecure device")
        case .authNFailure:
            handleAuthNFailure(context: context, action: action, completion: completion)
        case .authZFailure:
            handleAuthZFailure(context: context, action: action, completion: completion)
        case .noBillingZip:
            handleNoBillingZip(context: context, action: action, completion: completion)
        case .concurrency:
            handleConcurencyError(context: context, action: action, completion: completion)
        case .deviceZipRegion:
            handleDeviceZipWrongRegion(context: context, action: action, completion: completion)
        case .billingZipAuthorization:
            handleBillingZipAuthError(context: context, action: action, completion: completion)
        case .deviceZipProduct:
            handleDeviceZipNotAllowedProduct(context: context, action: action, completion: completion)
        case .billingZipProduct:
            handleBillingZipNotAllowedProduct(context: context, action: action, completion: completion)
        case .noProgramsOnAir, .noPrograms:
            handleNoProgramsError(context: context, action: action, completion: completion)
        default:
            NonFatalErrorProvider.shared.recordUndefinedError(error: serverLogicalError)
            showErrorFor(code: serverLogicalError)
        }
    }

    func handle(locationError: LocationError) {
        switch locationError.code {
        case .invalidGeocode:
            showErrorFor(code: ServerLogicalError.incorrectZip, params: ["0"])
        case .managerError:
            showErrorFor(code: ServerLogicalError.locationNotDetermined)
        case .serviceDisabled:
            let action = AlertAction(title: "Enable Location Service") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.openURL(url)
                }

            }
            showAlert(title: ErrorConstants.errorTitle,
                      message: ErrorConstants.locationServicesTurnedOff,
                      type: .locationUnavailable,
                      alertAction: action,
                      completion: nil)
        }
    }

    func handle(otherError: Error) {
        showErrorFor(code: ServerLogicalError.undefined)
    }

    // MARK: - Server error handlers
    /// All next methods has a default impelemtation. If you want to make a custom handling you can just override them
    func handleAuthNFailure(context: AnyObject? = nil,
                            action: EmptyCompletion? = nil,
                            completion: BoolCompletion? = nil) {
        goToRegionOrScheduleScreen()
        showErrorFor(code: ServerLogicalError.authNFailure)
    }

    func handleAuthZFailure(context: AnyObject? = nil,
                            action: EmptyCompletion? = nil,
                            completion: BoolCompletion? = nil) {
        goToRegionOrScheduleScreen()

        var mvpd = ErrorConstants.mvpdName
        if let context = context as? [String: String], let mvpdName = context[ContextKey.mvpd] {
            mvpd = mvpdName
        } else if let mvpdName = AccessEnablerManager.shared.mvpdName {
            mvpd = mvpdName
        }

        showErrorFor(code: ServerLogicalError.authZFailure, params: [mvpd])
    }

    func handleNoBillingZip(context: AnyObject? = nil,
                            action: EmptyCompletion? = nil,
                            completion: BoolCompletion? = nil) {
        goToRegionOrScheduleScreen()
        showErrorFor(code: ServerLogicalError.noBillingZip)
    }

    func handleConcurencyError(context: AnyObject? = nil,
                               action: EmptyCompletion? = nil,
                               completion: BoolCompletion? = nil) {
        goToRegionOrScheduleScreen()
        showErrorFor(code: ServerLogicalError.concurrency)
    }

    func handleDeviceZipWrongRegion(context: AnyObject? = nil,
                                    action: EmptyCompletion? = nil,
                                    completion: BoolCompletion? = nil) {
        goToRegionOrScheduleScreen()
        showErrorFor(code: ServerLogicalError.deviceZipRegion)
    }

    func handleBillingZipAuthError(context: AnyObject? = nil,
                                   action: EmptyCompletion? = nil,
                                   completion: BoolCompletion? = nil) {
        var mvpd = ErrorConstants.mvpdName
        var alternate = ErrorConstants.alternateProgram
        var alertAction: AlertAction?

        if let context = context as? [String: Any] {
            if let mvpdName = context[ContextKey.mvpd] as? String {
                mvpd = mvpdName
            }
            if let altName = context[ContextKey.alternate] as? String {
                alternate = altName
            }

            if let action = action {
                alertAction = AlertAction(title: alternate, action: action)
            }
        }

        showErrorFor(code: ServerLogicalError.billingZipAuthorization,
                     params: [mvpd, alternate],
                     extendedMessage: true,
                     alertAction: alertAction,
                     completion: completion)
    }

    func handleDeviceZipNotAllowedProduct(context: AnyObject? = nil,
                                          action: EmptyCompletion? = nil,
                                          completion: BoolCompletion? = nil) {

        var alternate = ErrorConstants.alternateProgram
        var alertAction: AlertAction?

        if let context = context as? [String: Any] {
            if let altName = context[ContextKey.alternate] as? String {
                alternate = altName
            }

            if let action = action {
                alertAction = AlertAction(title: alternate, action: action)
            }
        }

        showErrorFor(code: ServerLogicalError.deviceZipProduct,
                     params: [alternate],
                     extendedMessage: true,
                     alertAction: alertAction,
                     completion: completion)
    }

    func handleBillingZipNotAllowedProduct(context: AnyObject? = nil,
                                           action: EmptyCompletion? = nil,
                                           completion: BoolCompletion? = nil) {
        var alternate = ErrorConstants.alternateProgram
        var alertAction: AlertAction?

        if let context = context as? [String: Any] {
            if let altName = context[ContextKey.alternate] as? String {
                alternate = altName
            }

            if let action = action {
                alertAction = AlertAction(title: alternate, action: action)
            }
        }

        showErrorFor(code: ServerLogicalError.billingZipProduct,
                     params: [alternate],
                     extendedMessage: true,
                     alertAction: alertAction,
                     completion: completion)
    }

    func handleNoProgramsError(context: AnyObject? = nil,
                               action: EmptyCompletion? = nil,
                               completion: BoolCompletion? = nil) {
        var alternate = ErrorConstants.alternateProgram
        var alertAction: AlertAction?
        var extendedMessage = false

        if let context = context as? [String: Any] {
            if let altName = context[ContextKey.alternate] as? String {
                alternate = altName
                extendedMessage = true
            }

            if let action = action {
                alertAction = AlertAction(title: alternate, action: action)
            }
        }

        showErrorFor(code: ServerLogicalError.noProgramsOnAir,
                     params: [alternate],
                     extendedMessage: extendedMessage,
                     alertAction: alertAction,
                     completion: completion)
    }

    func goToRegionOrScheduleScreen() {
        CoreServices.shared.concurrencyProvider.deleteCurrentSession({ (_, _) in
            print("Deleted concurrency session")
        })

        navigationController?.popToRootViewController(animated: true)
    }

    // MARK: authorization logic
    func checkAuthorizationAndRun(resources: [String], completion: @escaping BoolCompletion) {
        let authProvider = CoreServices.shared.authorizationProvider

        if authProvider.isUserAuthorized && AccessEnablerManager.shared.isAuthorizedForResources(resources) {
            completion(true)
        } else {
            AccessEnablerManager.shared.showLoginCallback = {
                LoaderViewManager.sharedInstance.stopAnimation()
            }

            AccessEnablerManager.shared.hideLoginCallback = {(loggedIn: Bool) in
                if loggedIn {
                    LoaderViewManager.sharedInstance.startAnimation()
                }
            }

            AccessEnablerManager.shared.login(resources: resources, completion: { (success: Bool, error: Error?) in
                guard let mvpdName = AccessEnablerManager.shared.mvpdName else {
                    completion(false)
                    return
                }

                DispatchQueue.main.async {
                    self.updateUI()

                    if let error = error {
                        let context = [ContextKey.mvpd: mvpdName]
                        self.handle(error: error, context: context as AnyObject)

                        completion(false)
                        return
                    }
                }

                authProvider.startAuth { success, error in
                    if let error = error {
                        self.handle(error: error)
                        completion(false)

                        return
                    }
                    if success {
                        completion(true)
                    }

                }
            })
        }
    }
}
