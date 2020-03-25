//
//  SplashViewController.swift
//  RootSports
//
//  Created by Artak on 8/18/17.
//  Copyright © 2017 Ooyala. All rights reserved.
//

import Foundation

private enum SplashVCConstants {
    static let segueToChannelScheduleVCId = "showScheduleView"
    static let segueToAttRegionsVCId = "showRegionsView"
    static let segueToRootRegionsVCId = "showRootRegionsView"
}

class SplashViewController: BaseViewController {

    fileprivate var  regions: [RegionModel] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = Branding.splashBackgroundColor

        let count: UInt32 = 3
        let appId = "48425E30-8B73-4BCC-97EF-7D7F10388209" // is fake
        // isJailbroken() -> if not hacked: will return 4096. (2^10 = 1024 * 3 + 1024) = 4096
        guard calculateDeviceCompatibility(withAppID: appId) == UInt32(pow(2.0, 10.0)) * count + 1024 else {
            showAlertForError(code: ServerLogicalError.appSecurity, isPlayer: false, completion: { (_) in
                exit(0)
            })
            return
        }

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationWillEnterForeground(notification:)),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reachabilityChange(notification:)),
                                               name: ReachabilityChangedNotification,
                                               object: nil)

        // WARNING: if device is rooted, don't show anything to user
        loadData()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let navController = segue.destination as? UINavigationController else { return }

        switch segue.identifier {
        case SplashVCConstants.segueToChannelScheduleVCId:
            if let internalVC = navController.viewControllers[0] as? ChannelScheduleViewController,
                let region = self.regions.first {
                internalVC.currentRegion = region
            }

        case SplashVCConstants.segueToAttRegionsVCId:
            if let internalVC = navController.viewControllers[0] as? AttChooseRegionViewController,
                !self.regions.isEmpty {
                internalVC.currentRegions = self.regions
            }

        case SplashVCConstants.segueToRootRegionsVCId:
            if let internalVC = navController.viewControllers[0] as? ChannelsViewController,
                !self.regions.isEmpty {
                internalVC.currentRegions = self.regions
            }

        default: break
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return OrientationManager.supportedInterfaceOrientations(viewController: self)
    }

    override open var shouldAutorotate: Bool {
        return OrientationManager.shouldAutorotate(viewController: self)
    }

    // MARK: Private
    func loadData() {
        let scheduleProvider = CoreServices.shared.scheduleProvider

        scheduleProvider.config { (config: ConfigModel?, error: Error?) in
            guard let config = config else {
                if let error = error {
                    self.handle(error: error)
                }
                return
            }

            CoreServices.shared.config = config

            scheduleProvider.regions(applicationId: Branding.applicationId, completion: { (regions, error) in
                DispatchQueue.main.async {
                    guard error == nil else {
                        if let error = error {
                            self.handle(error: error)
                        }
                        return
                    }

                    if let regions = regions {
                        self.regions = regions
                    }

                    self.presentContent()
                }
            })
        }
    }

    fileprivate func presentContent() {
        if self.regions.count == 1 {
            return self.performSegue(withIdentifier: SplashVCConstants.segueToChannelScheduleVCId, sender: nil)
        }
        if self.regions.count > 1 {
            #if ATT
                self.performSegue(withIdentifier: SplashVCConstants.segueToAttRegionsVCId, sender: nil)
            #else
                self.performSegue(withIdentifier: SplashVCConstants.segueToRootRegionsVCId, sender: nil)
            #endif
        }
    }

    // MARK: Notification
    @objc func reachabilityChange(notification: Notification) {
        if let reachability = notification.object as? Reachability {
            print("Reachability change to " + reachability.currentReachabilityString)
            if reachability.currentReachabilityStatus != .notReachable && isViewLoaded {
                loadData()
            }
        }
    }

    @objc func applicationWillEnterForeground(notification: Notification) {
        loadData()
    }
}
