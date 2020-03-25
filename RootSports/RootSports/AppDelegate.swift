//
//  AppDelegate.swift
//  RootSports
//
//  Created by Artak on 7/31/17.
//  Copyright © 2017 Ooyala. All rights reserved.
//

import UIKit
import CoreData
import Fabric
import Crashlytics
import AVFoundation
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var orientationLock = UIInterfaceOrientationMask.all
    
   
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
//        #if !APPSTORE
            Fabric.with([Crashlytics.self])
//        #endif

        CoreServices.shared.firebaseService.start()
        
        var categoryError :NSError?
        var success: Bool
        do {
            // see https://developer.apple.com/documentation/avfoundation/avaudiosessioncategoryplayback
            // and https://developer.apple.com/documentation/avfoundation/avaudiosessionmodemovieplayback
            if #available(iOS 10.0, *) {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: .duckOthers)
            } else {
                // Fallback on earlier versions
            }
            success = true
        } catch let error as NSError {
            categoryError = error
            success = false
        }
        
        if !success {
            print("AppDelegate Debug - Error setting AVAudioSession category.  Because of this, there may be no sound. \(categoryError!)")
        }
        return true
    }

    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {

        if #available(iOS 10, *) {} else {
            CoreServices.shared.firebaseService.handleRemoteNotification(userInfo)
        }

        completionHandler(UIBackgroundFetchResult.newData)
    }

    func application(_ application: UIApplication,
                     supportedInterfaceOrientationsFor windoww: UIWindow?) -> UIInterfaceOrientationMask {
        
        if let win = windoww, let viewController = win.rootViewController {
            if viewController is AlertViewController {
                return viewController.supportedInterfaceOrientations
            }
        }

        return .allButUpsideDown
    }

    func application(_ app: UIApplication,
                     open url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) -> Bool {
        if url.absoluteString.hasPrefix("adbe.") {
            AccessEnablerManager.shared.handleExternalURL(url.description)

            //            if(svc != nil) {
            //                svc.dismiss(animated: true)
            //            }
            return true
        }

        return false

    }
    
    
}
