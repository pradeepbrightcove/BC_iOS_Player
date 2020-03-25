//
//  ConcurrencyProvider.swift
//  RootSports
//
//  Created by Olena Lysenko on 8/29/17.
//  Copyright © 2017 Ooyala. All rights reserved.
//

// http://docs.adobeptime.io/cm-api-v2

protocol ConcurrencyNetworkServiceProtocol {
    func createSession(mvpdId: String, subscriberId: String, completion: @escaping StringCompletion)
    func deleteSession(mvpdId: String, subscriberId: String, sessionId: String, completion: @escaping SuccessCompletion)
    func heartbeat(mvpdId: String, subscriberId: String, sessionId: String, completion: @escaping StringCompletion)
}

class ConcurrencyProvider {
    fileprivate var currentSessionId: String?
    fileprivate var currentMVPDId: String?
    fileprivate var currentUserId: String?

    private let networkService: ConcurrencyNetworkServiceProtocol

    var applicationId: String?

    init(networkService: ConcurrencyNetworkServiceProtocol) {
        self.networkService = networkService
    }

    func heartbeatCurrentSession(_ completion: @escaping StringCompletion) {
        guard let mvpdId = currentMVPDId,
            let subscriberId = currentUserId,
            let sessionId = currentSessionId
            else {
                completion(nil, ServerLogicalError.undefined)
                return
        }

        networkService.heartbeat(mvpdId: mvpdId,
                                 subscriberId: subscriberId,
                                 sessionId: sessionId,
                                 completion: completion)
    }

    func deleteCurrentSession(_ completion: @escaping SuccessCompletion) {
        guard let mvpdId = currentMVPDId,
            let subscriberId = currentUserId,
            let sessionId = currentSessionId
            else {
                completion(false, ServerLogicalError.undefined)
                return
        }

        networkService.deleteSession(mvpdId: mvpdId,
                                     subscriberId: subscriberId,
                                     sessionId: sessionId) { success, error in
            self.currentSessionId = nil
            self.currentUserId = nil
            self.currentMVPDId = nil

            completion(success, error)
        }
    }

    func createSession(mvpdId: String, subscriberId: String, completion: @escaping StringCompletion) {
        networkService.createSession(mvpdId: mvpdId, subscriberId: subscriberId) { (sessionId, error) in
            if sessionId != nil {
                self.currentMVPDId = mvpdId
                self.currentUserId = subscriberId
                self.currentSessionId = sessionId
            }

            completion(sessionId, error)
        }
    }
}
