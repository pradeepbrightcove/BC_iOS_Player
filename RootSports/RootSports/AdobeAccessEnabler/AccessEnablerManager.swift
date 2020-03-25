//
//  AccessEnablerManager.swift
//  RootSports
//
//  Created by Olena Lysenko on 8/15/17.
//  Copyright © 2017 Ooyala. All rights reserved.
//

import AccessEnabler

typealias SuccessCompletion = (_ success: Bool, _ error: Error?) -> Void

private enum Constants {
    static let zipKey = "zip"
//    static let subscriberIdKey = "upstreamUserID"
    static let userIdKey = "userID"
    static let upstreamUserIdKey = "upstreamUserID"
    static let selectedMVPDKey = "selectedMVPD"
    static let selectedMVPDNameKey = "selectedMVPDNameKey"

    static let deprecatedPreflightMvpds = ["Suddenlink", "auth_atlanticbb_net"]
}

enum AuthFlow {
    case none
    case login
    case checkAuthN
    case logout
}

class AccessEnablerManager: NSObject, EntitlementDelegate, EntitlementStatus {
    static let shared = AccessEnablerManager()

    var mvpds = [Any]()

    var requestedResources  = [String]()
    var authorizedResources = [String]()

    var encryptedZip: String?
    var subscriberId: String?
    var mvpdId: String? {
        return UserDefaults.standard.object(forKey: Constants.selectedMVPDKey) as? String
    }

    var mvpdName: String? {
        return UserDefaults.standard.object(forKey: Constants.selectedMVPDNameKey) as? String
    }

    var requestorId: String?

    var shortMediaToken: String?

    var isLoggedIn = false

    var showLoginCallback: EmptyCompletion?
    var hideLoginCallback: BoolCompletion?

    private var loginNavigationController: UINavigationController?

    private var currentFlow: AuthFlow = .none

    var loginCompletion: SuccessCompletion?
    var logoutCompletion: SuccessCompletion?

    private var accessEnabler: AccessEnabler?

    func createAccessEnabler(softwareStatement: String) {
        if accessEnabler == nil {
            let accessEnabler = AccessEnabler(softwareStatement)
            accessEnabler.delegate = self
            accessEnabler.statusDelegate = self
            self.accessEnabler = accessEnabler
        }
    }

    func login(resources: [String], completion:@escaping SuccessCompletion) {
        loginCompletion = completion
        currentFlow = .login
        requestedResources = Array(Set(resources))
        startPreauthorization()
    }

    func logout(completion:@escaping SuccessCompletion) {
        logoutCompletion = completion

        if isLoggedIn {
            currentFlow = .logout
            accessEnabler?.logout()
        }
    }

    func checkLoginStatus(completion:@escaping SuccessCompletion) {
        if isLoggedIn { return completion(true, nil) }

        currentFlow = .checkAuthN
        loginCompletion = completion
        setRequestorId()
    }

//    func getAuthenticationToken() {
//        accessEnabler.getAuthenticationToken()
//    }

    func handleExternalURL(_ url: String?) {
        accessEnabler?.handleExternalURL(url)
    }

    func isAuthorizedForResources(_ resources: [String]) -> Bool {
        if authorizedResources.count == 0 {
            return false
        }

        return Set(authorizedResources).isSuperset(of: Set(resources))
    }

    // MARK: Private
    private func startPreauthorization() {
        mvpds = []
        setRequestorId()
    }

    private func setRequestorId() {
        CoreServices.shared.authorizationProvider.requestorId { [unowned self] requestorModel, error in
            guard let requestor = requestorModel else {
                if let loginCompletion = self.loginCompletion {
                    loginCompletion(false, error)
                }
                self.currentFlow = .none
                return
            }

            DispatchQueue.main.async {
                self.createAccessEnabler(softwareStatement: requestor.softwareStatement)
                self.requestorId = requestor.requestorId
                #if APPSTORE
                self.accessEnabler?.setRequestor(self.requestorId!)
                #else
                self.accessEnabler?.setRequestor(self.requestorId!)
         //       self.accessEnabler?.setRequestor(self.requestorId!,
                                                  //  serviceProviders: ["sp.auth-staging.adobe.com/adobe-services"])
                #endif
            }
        }
    }

    private func showUserAgreement() {
        let storyboard = UIStoryboard(name: "AccessEnabler", bundle: nil)
        guard let userAgreementController = storyboard
            .instantiateViewController(withIdentifier: "UserAgreementViewController")
            as? UserAgreementViewController else { return }

        let menuKey = ModelConstants.UserAgreementValue

        guard let firstRegionCode = CoreServices.shared.scheduleProvider.regions.first?.regionCode,
            let menu = CoreServices.shared.config.menuItems[firstRegionCode]?.filter({ $0.key == menuKey }).first else {
            return
        }

        userAgreementController.html = menu.data

        userAgreementController.declineAction = {
            userAgreementController.dismiss(animated: true, completion: nil)
        }

        userAgreementController.agreeAction = {
            userAgreementController.dismiss(animated: false, completion: {
                self.showMVPDPicker()
            })
        }

        guard let window = UIApplication.shared.delegate?.window else {
            return print("Could not preset picker")
        }

        if let callback = showLoginCallback {
            callback()
        }

        window?.rootViewController?.presentedViewController?.present(userAgreementController,
                                                                     animated: true,
                                                                     completion: nil)
    }

    private func showMVPDPicker() {
        let storyboard = UIStoryboard(name: "AccessEnabler", bundle: nil)

        let navigationController =
            storyboard.instantiateViewController(withIdentifier: "AccessEnablerNavigationController")
                as? UINavigationController
        guard let mvpdPicker =
            navigationController?.viewControllers[0] as? MVPDPickerViewController else { return }

        mvpdPicker.mvpds = mvpds

        mvpdPicker.selectionHandler = { [unowned self] selectedMVPD in
            print("selected mvpd:" + selectedMVPD.id)

            self.accessEnabler?.setSelectedProvider(selectedMVPD.id)

            UserDefaults.standard.set(selectedMVPD.id, forKey: Constants.selectedMVPDKey)
            UserDefaults.standard.set(selectedMVPD.displayName, forKey: Constants.selectedMVPDNameKey)
        }

        mvpdPicker.dismissCallback = hideLoginCallback

        loginNavigationController = navigationController

        guard let window = UIApplication.shared.delegate?.window else {
            return print("Could not preset picker")
        }

        if let callback = showLoginCallback {
            callback()
        }

        window?.rootViewController?.presentedViewController?.present(navigationController!,
                                                                     animated: true,
                                                                     completion: nil)
    }

    private func showProviderLogin(_ url: String!) {
        if let loginNavigationController = loginNavigationController,
            !(loginNavigationController.topViewController is MVPDLoginViewController) {
            guard let loginVC = loginNavigationController.storyboard?
                .instantiateViewController(withIdentifier: "MVPDLoginViewController")
                as? MVPDLoginViewController else { return }

            loginVC.loginUrl = url
            loginVC.dismissCallback = hideLoginCallback

            loginNavigationController.pushViewController(loginVC, animated: true)
        }
    }

    private func cleanup() {
        isLoggedIn = false

        currentFlow = .none

        requestedResources = []
        authorizedResources = []

        mvpds = []

        encryptedZip = nil

        subscriberId = nil
        requestorId = nil

        shortMediaToken = nil

        UserDefaults.standard.removeObject(forKey: Constants.selectedMVPDKey)
        UserDefaults.standard.removeObject(forKey: Constants.selectedMVPDNameKey)

        let storage = HTTPCookieStorage.shared
        if let cookies = storage.cookies {
            for cookie in cookies {
                storage.deleteCookie(cookie)
            }
        }
    }

    // MARK: EntitlementDelegate
    func presentTvProviderDialog(_ viewController: UIViewController!) {
        print("presentTvProviderDialog")
    }

    func dismissTvProviderDialog(_ viewController: UIViewController!) {
        print("dismissTvProviderDialog")
    }

    func setRequestorComplete(_ status: CInt) {
        print("setRequestorComplete \(status)")
        if status == 1 {
            accessEnabler?.getAuthentication()
        }
    }

    func setAuthenticationStatus(_ status: CInt, errorCode code: String!) {
        print("setAuthenticationStatus(\(status), \(code ?? ""))")

        isLoggedIn = status == 1

        if isLoggedIn {
            accessEnabler?.checkPreauthorizedResources(requestedResources)
        } else if currentFlow == .login {
            if let loginCompletion = self.loginCompletion {
                loginCompletion(false, ServerLogicalError.undefined)
            }

            cleanup()
        }
    }

    func setToken(_ token: String!, forResource resource: String!) {
        print("=======================================")
        print("setToken \(token ?? "") for Resource \(resource ?? "")")
        print("=======================================")

        accessEnabler?.getMetadata([METADATA_OPCODE_KEY: Int(METADATA_USER_META),
                                    METADATA_USER_META_KEY: Constants.zipKey])
        accessEnabler?.getMetadata([METADATA_OPCODE_KEY: Int(METADATA_USER_META),
                                    METADATA_USER_META_KEY: Constants.upstreamUserIdKey])
        shortMediaToken = token
    }

    func resultHandler(success: Bool, error: Error?) {
        if let completion = self.loginCompletion {
            completion(success, error)

            self.loginCompletion = nil
            self.currentFlow = .none

            if !success {
                self.logout(completion: { _, _ in })
            }
        }
    }

    func preauthorizedResources(_ resources: [Any]!) {
        print("=======================================")
        print("preauthorizedResources \(resources ?? [])")
        print("=======================================")

        if currentFlow == .checkAuthN || currentFlow == .login && requestedResources.count == 0 {
            return resultHandler(success: true, error: nil)
        }

        if requestedResources.count > 0 {
            guard let receivedResources = resources as? [String] else {
                return resultHandler(success: false, error: ServerLogicalError.authZFailure)
            }

            if receivedResources.count > 0 {
                authorizedResources = receivedResources
            } else {
                if let selectedProviderId = UserDefaults.standard.string(forKey: Constants.selectedMVPDKey),
                    Constants.deprecatedPreflightMvpds.contains(selectedProviderId),
                    let resource = requestedResources.first {
                    authorizedResources = [resource]
                } else {
                    return resultHandler(success: false, error: ServerLogicalError.authZFailure)
                }
            }
            accessEnabler?.getAuthorization(authorizedResources.first)
        }
    }

    func tokenRequestFailed(_ resource: String!,
                            errorCode code: String!,
                            errorDescription description: String!) {
        print("tokenRequestFailed")
        if code == USER_NOT_AUTHORIZED_ERROR {
            resultHandler(success: false, error: ServerLogicalError.authZFailure)
        }
    }

    func selectedProvider(_ mvpd: MVPD!) {
        print("SELECTED PROVIDER: ")
        print(mvpd)
    }

    func displayProviderDialog(_ mvpds: [Any]!) {
        for mvpd in mvpds {
            guard let mvpdNotNil = mvpd as? MVPD else { continue }
            print("MVPD: \(mvpdNotNil.id ?? "")")
            print("MVPD: \(mvpdNotNil.logoURL ?? "")")
        }

        if currentFlow == .checkAuthN {
            if let completion = loginCompletion {
                completion(false, nil)
            }

            loginCompletion = nil
            currentFlow = .none

            return

        } else if currentFlow != .login {
            return
        }

        let blacklistedMvpdIds = CoreServices.shared.config.blacklistedMvpdIds

        var filteredMvpds = mvpds

        if blacklistedMvpdIds.count > 0 {
            filteredMvpds = mvpds.filter { (mvpd: Any) -> Bool in
                if let mvpdId = (mvpd as? MVPD)?.id {
                    if blacklistedMvpdIds.contains(mvpdId) {
                        return false
                    }
                }

                return true
            }
        }

        if filteredMvpds?.count == 0 {
            showAlertView(title: "Error", message: "No providers are available at this time.")
        }

        DispatchQueue.main.async(execute: { [unowned self] in
            self.mvpds = filteredMvpds!

            if hasUserAgreement() {
                self.showMVPDPicker()
            } else {
                self.showUserAgreement()
            }
        })
    }

    func sendTrackingData(_ data: [Any]!, forEventType event: CInt) {
        var eventType: String = ""

        switch event {
        case 0:
            eventType = "Authentication detection"
        case 1:
            eventType = "Authorization detection"
        case 2:
            eventType = "MVPD selection detection"
        default:
            break
        }

        print("sendTrackingData \(eventType)")
    }

    func setMetadataStatus(_ metadata: Any!,
                           encrypted: Bool,
                           forKey key: CInt,
                           andArguments arguments: [AnyHashable: Any]!) {
        print("=======================================")

        var keyName = ""
        var metadataValue = ""

        switch key {
        case 0:
            keyName = "AUTHN_TTL"

        case 1:
            keyName = "AUTHZ_TTL"

        case 2:
            keyName = "deviceId"

        default:
            if let metadataName = arguments["user_metadata_name"] as? String {
                keyName = metadataName
            }

        }

        if metadata != nil {
            if metadata is String, let mdString = metadata as? String {
                metadataValue = mdString
            } else if metadata is NSArray, let mdNSArray = metadata as? NSArray {
                let metadataArray = mdNSArray
                metadataValue = metadataArray.componentsJoined(by: ",")
            } else if metadata is NSDictionary, let mdDict = metadata as? [String: Any] {
                let metadataDictionary = mdDict
                metadataValue = (metadataDictionary.compactMap({ key, value -> String in
                    return "\(key) = \(value)"
                }) as Array).joined(separator: ",")
            }
        }

        if keyName == Constants.zipKey {
            if !metadataValue.isEmpty {
                encryptedZip = metadataValue
            } else {
                if let completion = loginCompletion {
                    completion(false, ServerLogicalError.noBillingZip)
                }

                loginCompletion = nil

                logout(completion: { (_, _) in
                })
            }

        } else if keyName == Constants.upstreamUserIdKey || keyName == Constants.userIdKey {
            if metadataValue.isEmpty && keyName == Constants.upstreamUserIdKey {
                print("Missing Upstream User ID, getting User ID")
                accessEnabler?.getMetadata([METADATA_OPCODE_KEY: Int(METADATA_USER_META),
                                            METADATA_USER_META_KEY: Constants.userIdKey])
            } else {
                subscriberId = metadataValue
            }
        }

        if encryptedZip != nil && subscriberId != nil {
            if let completion = loginCompletion {
                completion(true, nil)
            }

            loginCompletion = nil
            currentFlow = .none
        }
    }

    func navigate(toUrl url: String!) {
        print("navigateToUrl: " + url)

        switch currentFlow {
        case .logout:
            guard let urlObj = URL(string: url) else { return }
            let task = URLSession.shared.dataTask(with: urlObj) { _, _, error in
                if let error = error {
                    print("Error logging out " + error.localizedDescription)
                }

                self.cleanup()

                if let completion = self.logoutCompletion {
                    completion(true, nil)
                }

                self.logoutCompletion = nil
            }

            task.resume()

        case .checkAuthN:
            if let completion = self.loginCompletion {
                completion(false, nil)
            }

            self.loginCompletion = nil
            self.currentFlow = .none

        default:
            DispatchQueue.main.async { [unowned self] in
                self.showProviderLogin(url)
            }
        }

    }

    // MARK: End EntitlementDelegate
    // MARK: EntitlementStatus
    func status(_ statusDictionary: [AnyHashable: Any]!) {
        print("STATUS: \(statusDictionary ?? [:])")
    }
}
