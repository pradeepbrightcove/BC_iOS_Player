//
//  AuthorizationProvider.swift
//  RootSports
//
//  Created by Sergii Shulga on 8/14/17.
//  Copyright © 2017 Ooyala. All rights reserved.
//

import Foundation

protocol AuthorizationNetworkServiceProtocol {
    func programMeta(regionCode: String, deviceZip: String, token: String, completion: @escaping NetworkArrayCompletion)
    func requestorId(completion: @escaping (_ program: [String: Any]?, _ error: Error?) -> Void)
    func startAuth(shortMediaToken: String,
                   billingZip: String,
                   userId: String,
                   completion: @escaping (_ tokenDict: [String: Any]?, _ error: Error?) -> Void)
    func subscribe(fcmToken: String, authToken: String, completion: @escaping EmptyCompletion)
    func signData(_ dataString: String, token: String) -> (String, Bool)
}

protocol AuthorizationLocationProtocol {
    func zipCode(completion: @escaping LocationZipHandler)
}

protocol Program {
    var priority: ChannelPriority { get }
    var programCode: String { get }
    var channelCode: String { get }
    var programTitle: String? { get }
    var programTitleBrief: String? { get }
    var resourceId: String { get }
    var live: Bool { get }
}

protocol AuthorizedProgram: Program {
    var embedCode: String { get }
    var pCode: String { get }
    var opt: String { get }
    var apiKey: String { get }
}

class AuthorizationProvider: BaseProvider {
    private let networkService: AuthorizationNetworkServiceProtocol
    private let locationManager: AuthorizationLocationProtocol

    private var jwt: String?

    var token: String? {
        return jwt
    }

    var isUserAuthorized: Bool {
        return AccessEnablerManager.shared.shortMediaToken != nil && jwt != nil
    }

    init(networkService: AuthorizationNetworkServiceProtocol, locationManager: AuthorizationLocationProtocol) {
        self.networkService = networkService
        self.locationManager = locationManager
    }

    func sign(_ data: String) -> (String, Bool) {
        guard let token = jwt else {
            return ("", false)
        }

        return self.networkService.signData(data, token: token)
    }

    func programMeta(_ program: Program,
                     regionCode: String,
                     completion: @escaping (_ program: [AuthorizedProgram]?, _ error: Error?) -> Void) {
        programMeta(programCode: program.programCode,
                    channelCode: program.channelCode,
                    regionCode: regionCode,
                    completion: completion)
    }

    func programMeta(programCode: String,
                     channelCode: String,
                     regionCode: String,
                     completion: @escaping (_ program: [AuthorizedProgram]?, _ error: Error?) -> Void) {
        guard let token = jwt else { return completion(nil, ServerLogicalError.noBillingZip) }

        locationManager.zipCode { (zipCode, error) in
            guard error == nil, let zipCode = zipCode else {
                completion(nil, error)

                NonFatalErrorProvider.shared.debugInfo[DebugInfoKey.deviceZip] =
                    "Could not retrieve device zip: " + error.debugDescription
                return
            }

            NonFatalErrorProvider.shared.debugInfo[DebugInfoKey.deviceZip] = zipCode

//            let utf8data = "94102".data(using: .utf8)
            let utf8data = zipCode.data(using: .utf8)

            guard let encodedZip = utf8data?.base64EncodedString(options: []) else {
                completion(nil, ServerLogicalError.deviceZipRegion)
                return
            }

            self.networkService.programMeta(regionCode: regionCode,
                                            deviceZip: encodedZip,
                                            token: token) { [unowned self] (response, error) in
                guard error == nil else {
                    print("Received error in programMeta \(String(describing: error))")
                    if let error = error as? ResponseError {
                        if  error == ResponseError.expiredJWT {
                            self.startAuth({ (success, error) in
                                if success {
                                    self.programMeta(programCode: programCode,
                                                     channelCode: channelCode,
                                                     regionCode: regionCode,
                                                     completion: completion)
                                } else {
                                    completion(nil, error)
                                }
                            })
                            return
                        }
                    }

                    completion(nil, error)
                    return
                }

                var programs = [AuthorizedProgram]()
                var programError: ServerLogicalError?

                enum ResponseState {
                    case okay
                    case programError
                    case notFound
                }

                var state = ResponseState.notFound

                if let dicts = response {
                    for programDict in dicts {
                        if let program = AuthorizedProgramModel(fromDictionary: programDict) {
                            if AccessEnablerManager.shared.authorizedResources.contains(program.resourceId) {
                                programs.append(program)
                               
                                if /*programCode == program.programCode ||*/ channelCode == program.channelCode {
                                    state = .okay
                                    programError = nil
                                }

                            } else {
                                if /*programCode == program.programCode ||*/
                                    channelCode == program.channelCode && state != .okay {
                                    state = .programError
                                    programError = ServerLogicalError.authZFailure
                                }
                            }

                        } else if let serverError = self.processLogicError(programDict), state == .notFound {
                            if programCode == programDict[ModelConstants.ProgramCodeField] as? String {
                                state = .programError
                            }
                            programError = serverError
                        }
                    }

                    programs.sort(by: { $0.priority.rawValue < $1.priority.rawValue })

                    completion(programs, programError)
                } else {
                    completion(nil, ResponseError.unexpectedFormat)
                }
            }
        }
    }

    func requestorId(_ completion: @escaping (_ program: RequestorModel?, _ error: Error?) -> Void) {
        networkService.requestorId { requestorDict, error in
            print(requestorDict as Any)

            if let requestorDict = requestorDict,
               let requestor = RequestorModel(fromDictionary: requestorDict) {
                CoreServices.shared.concurrencyProvider.applicationId = requestor.concurrencyId

                completion(requestor, nil)
            } else {
                completion(nil, error)
            }
        }
    }

    func startAuth(_ completion: @escaping (_ success: Bool, _ error: Error?) -> Void) {
        guard let mediaToken = AccessEnablerManager.shared.shortMediaToken else {
            let resources = AccessEnablerManager.shared.authorizedResources

            AccessEnablerManager.shared.login(resources: resources, completion: { success, error in
                if success {
                    self.startAuth(completion)
                } else {
                    completion(false, error)
                }
            })
            return
        }

        guard let billingZip = AccessEnablerManager.shared.encryptedZip,
            let userId = AccessEnablerManager.shared.subscriberId else {
                return completion(false, ServerLogicalError.undefined)
        }

        networkService.startAuth(shortMediaToken: mediaToken,
                                 billingZip: billingZip,
                                 userId: userId) { tokenDict, error in
            print("Starting auth with token: \(mediaToken), zip: \(billingZip), userId: \(userId)")

            if let tokenDict = tokenDict, let token = tokenDict[ModelConstants.TokenField] as? String {
                self.jwt = token

                print("=======================================")
                print("Received JWT from B2C")
                print(tokenDict as Any)
                print("=======================================")

                completion(true, nil)

            } else {
                print("Failed to receive JWT from B2C \(String(describing: error))")

                completion(false, error)
            }
        }
    }

    func subscribe(token: String, completion: @escaping EmptyCompletion) {
        guard let authToken = jwt else {
            completion()
            return
        }

        networkService.subscribe(fcmToken: token, authToken: authToken) {
            completion()
        }
    }

    func invalidateAuth() {
        jwt = nil
    }
}
