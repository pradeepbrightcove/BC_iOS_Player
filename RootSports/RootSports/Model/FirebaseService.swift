//
//  FirebaseService.swift
//  RootSports
//
//  Created by Sergii Shulga on 9/6/17.
//  Copyright © 2017 Ooyala. All rights reserved.
//

import Foundation
import Firebase

private enum Constants {
    static let FromField = "from"
    static let TopicName = "channels"
}

protocol FirebaseServiceObserver: NSObjectProtocol {
    func firebaseService(_ service: FirebaseService, didReceiveChannelsUpdate channelDicts: [String: String])
}

class FirebaseService: NSObject {

    fileprivate var observers = [FirebaseServiceObserver]()

    // MARK: Public

    func start() {
        FirebaseApp.configure()

        Messaging.messaging().delegate = self
        Messaging.messaging().shouldEstablishDirectChannel = true

        // We should subscribe after delay, because of error inside Firebase library
        //
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 5) {
            Messaging.messaging().subscribe(toTopic: Constants.TopicName)
        }
    }

    func add(observer: FirebaseServiceObserver) {
        observers.append(observer)
    }

    func remove(observer: FirebaseServiceObserver) {
        observers = observers.filter({$0 !== observer})
    }

    func handleRemoteNotification(_ userInfo: [AnyHashable: Any]) {
        guard let data = userInfo as? [String: String],
            data[Constants.FromField] == "/topics/\(Constants.TopicName)" else {
            return
        }

        for observer in observers {
            observer.firebaseService(self, didReceiveChannelsUpdate: data)
        }
    }
}

extension FirebaseService: MessagingDelegate {

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        print("Firebase registration token: \(fcmToken)")
    }

    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        print("Received data message: \(remoteMessage.appData)")

        handleRemoteNotification(remoteMessage.appData)
    }

}
