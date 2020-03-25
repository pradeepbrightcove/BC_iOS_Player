//
//  NetworkService.swift
//  RootSports
//
//  Created by Sergii Shulga on 8/9/17.
//  Copyright © 2017 Ooyala. All rights reserved.
//

import Foundation

    #if APPSTORE
let baseURL = "https://root-b2c.ges.ps.ooyala.com" // production
    #else
let baseURL = "https://root-b2c.ges.ps.ooyala.com" // staging
    #endif

let baseHeaderName = "x-version-code"
let baseHeaderValue = "\(ModelConstants.PlatformValue);\(Branding.applicationId);" +
                      "\(AppInfo.version);\(AppInfo.build)"

let authExpiredCode = 403
let mediaTokenExpiredCode = 401

typealias NetworkDictionaryCompletion = (_ response: [String: Any]?, _ error: Error?) -> Void
typealias NetworkArrayCompletion      = (_ response: [[String: Any]]?, _ error: Error?) -> Void
typealias StringCompletion            = (_ response: String?, _ error: Error?) -> Void

enum ResponseError: Error {
    case noInternet
    case jsonParsing
    case unexpectedFormat
    case expiredJWT
}

enum AppInfo {
    static let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    static let build = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String ?? ""
}

class NetworkService {

    fileprivate let session: URLSession
    fileprivate let reachability: Reachability

    init() {
        let config = URLSessionConfiguration.default
        self.session = URLSession(configuration: config)
        self.reachability = Reachability(/*hostname: baseURL*/)!

        do {
            try self.reachability.startNotifier()
        } catch { }
    }

    fileprivate func getRequest(path: String, parameters: [String: Any]) -> URLRequest? {

        let requestURLString = baseURL + path

        var components = URLComponents(string: requestURLString)

        if parameters.count > 0 {
            var items = [URLQueryItem]()

            for (key, value) in parameters {
                items.append(URLQueryItem(name: key, value: String(describing: value)))
            }

            components?.queryItems = items
        }

        let url = components?.url
        var request = URLRequest(url: url!)
        request.httpMethod = "GET"
        request.setValue(baseHeaderValue, forHTTPHeaderField: baseHeaderName)

        return request
    }

    fileprivate func authGetRequest(path: String, parameters: [String: Any], token: String) -> URLRequest? {

        var request = getRequest(path: path, parameters: parameters)
        request?.setValue("Bearer \(token)", forHTTPHeaderField: ModelConstants.AuthorizationField)

        return request
    }

    fileprivate func postRequest(path: String, parameters: [String: Any]) -> URLRequest? {
        let requestURLString = baseURL + path

        let components = URLComponents(string: requestURLString)

        let url = components?.url
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(baseHeaderValue, forHTTPHeaderField: baseHeaderName)

        if parameters.count > 0 {
            do {
                let data = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
                request.httpBody = data
            } catch {
                print("error creating json")
            }
        }

        return request
    }

    fileprivate func processResponse<T: Collection>(data: Data?) throws -> T {//[String: Any] {
        if let jsonData = data {
            do {
                let json = try JSONSerialization.jsonObject(with: jsonData)

                if let jsonObject = json as? T {
                    return jsonObject
                } else {
                    NonFatalErrorProvider.shared.recordUndefinedError(error: ResponseError.unexpectedFormat, data: data)
                    throw ResponseError.unexpectedFormat
                }
            } catch {
                print("Error parsing JSON")
                if data != nil {
                    print("data \(String(describing: String(data: data!, encoding: .utf8)))")
                } else {
                    print("no data")
                }
                NonFatalErrorProvider.shared.recordUndefinedError(error: ResponseError.jsonParsing, data: data)
                throw ResponseError.jsonParsing
            }
        } else {
            NonFatalErrorProvider.shared.recordUndefinedError(error: ResponseError.unexpectedFormat, data: data)
            throw ResponseError.unexpectedFormat
        }
    }
}

// MARK: - ScheduleNetworkServiceProtocol
extension NetworkService: ScheduleNetworkServiceProtocol {
    private func configGetRequest() -> URLRequest? {
        return getRequest(path: "/config", parameters: [:])
    }

    func config(_ completion: @escaping NetworkDictionaryCompletion) {
        guard reachability.currentReachabilityStatus != .notReachable else {
            completion(nil, ResponseError.noInternet)
            return
        }

        let request = configGetRequest()

        let task = session.dataTask(with: request!) { (data, _, error) in

            guard error == nil else {
                NonFatalErrorProvider.shared.recordUndefinedError(error: error, data: data)
                completion(nil, error)
                return
            }

            do {
                let dict: [String: Any] = try self.processResponse(data: data)
//                print("Config dict \(dict)")
                completion(dict, nil)
            } catch {
                completion(nil, error)
            }
        }

        task.resume()
    }

    private func scheduleGetRequest(parameters: [String: Any]) -> URLRequest? {
        return getRequest(path: "/schedule", parameters: parameters)
    }

    func schedule(region: String,
                  date: Int?,
                  deviceZip: String? = nil,
                  token: String? = nil,
                  completion: @escaping NetworkDictionaryCompletion) {

        guard reachability.currentReachabilityStatus != .notReachable else {
            completion(nil, ResponseError.noInternet)
            return
        }

        var params = [String: Any]()

        params[ModelConstants.RegionCodeField] = region

        if let existingDate = date {
            params[ModelConstants.StartTimeField] = existingDate
        }

        var request: URLRequest?

        if let deviceZip = deviceZip, let token = token {
            params["device_zip"] = deviceZip

            request = authGetRequest(path: scheduleGetRequest(parameters: params)?.url?.path ?? "",
                                     parameters: params,
                                     token: token)
        } else {
            request = scheduleGetRequest(parameters: params)
        }

        let task = session.dataTask(with: request!) { (data, _, error) in

            guard error == nil else {
                NonFatalErrorProvider.shared.recordUndefinedError(error: error, data: data)
                completion(nil, error)
                return
            }

            do {
                let dict: [String: Any] = try self.processResponse(data: data)
                completion(dict, nil)
            } catch {
                completion(nil, error)
            }
        }

        task.resume()
    }

    private func regionGetRequest(parameters: [String: Any]) -> URLRequest? {
        return getRequest(path: "/region", parameters: parameters)
    }

    func regions(applicationId: String, completion: @escaping (_ regions: [[String: Any]?]?, _ error: Error?) -> Void) {

        guard reachability.currentReachabilityStatus != .notReachable else {
            completion(nil, ResponseError.noInternet)
            return
        }

        var params = [String: Any]()

        params[ModelConstants.ApplicationIDField] = applicationId

        let request = regionGetRequest(parameters: params)

        let task = session.dataTask(with: request!) { (data, _, error) in

            guard error == nil else {
                NonFatalErrorProvider.shared.recordUndefinedError(error: error, data: data)
                completion(nil, error)
                return
            }

            do {
                let dicts: [[String: Any]] = try self.processResponse(data: data)
                completion(dicts, nil)
            } catch {
                completion(nil, error)
            }
        }

        task.resume()
    }

    func currentProgram(channelCode: String, completion: @escaping NetworkDictionaryCompletion) {
        let request = getRequest(path: "/currentProgram",
                                 parameters: [ModelConstants.ChannelField: channelCode])

        let task = session.dataTask(with: request!) { (data, _, error) in

            guard error == nil else {
                NonFatalErrorProvider.shared.recordUndefinedError(error: error, data: data)
                completion(nil, error)
                return
            }

            do {
                let dict: [String: Any] = try self.processResponse(data: data)
                completion(dict, nil)
            } catch {
                completion(nil, error)
            }
        }

        task.resume()
    }

}

// MARK: - AuthorizationNetworkServiceProtocol

extension NetworkService: AuthorizationNetworkServiceProtocol {
    func signData(_ dataString: String, token: String) -> (String, Bool) {

        let params = ["in": dataString]

        let request = authGetRequest(path: "/sign", parameters: params, token: token)

        var success = false
        var result = ""

        let semaphore = DispatchSemaphore(value: 0)

        let task = URLSession.shared.dataTask(with: request!, completionHandler: { data, response, error in
            if let error = error {
                print("Error getting signed data: \(error)")
            } else if let response = response as? HTTPURLResponse,
                300..<600 ~= response.statusCode {
                print("Error getting signed data, statusCode: \(response.statusCode)")
            } else {
                result = String(data: data!, encoding: .utf8)!
                print("received data from sign: " + result)
                success = true
            }
            semaphore.signal()
        })

        task.resume()
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)

        return (result, success)
    }

    func programMeta(regionCode: String,
                     deviceZip: String,
                     token: String,
                     completion: @escaping NetworkArrayCompletion) {

        guard reachability.currentReachabilityStatus != .notReachable else {
            completion(nil, ResponseError.noInternet)
            return
        }

        let params = [ModelConstants.RegionCodeField: regionCode,
                      ModelConstants.DeviceZIPField: deviceZip]

        let request = authGetRequest(path: "/programMeta", parameters: params, token: token)

        let task = session.dataTask(with: request!) { (data, response, error) in
            do {
                _ = try self.checkAuthStateInResponse(response)
            } catch {
                NonFatalErrorProvider.shared.recordUndefinedError(error: error, data: data)
                NonFatalErrorProvider.shared.debugInfo[DebugInfoKey.programMeta] = error

                completion(nil, error)
                return
            }

            guard error == nil else {
                NonFatalErrorProvider.shared.recordUndefinedError(error: error, data: data)
                NonFatalErrorProvider.shared.debugInfo[DebugInfoKey.programMeta] = error

                completion(nil, error)
                return
            }

            do {
                let dicts: [[String: Any]] = try self.processResponse(data: data)
                completion(dicts, nil)

                NonFatalErrorProvider.shared.debugInfo[DebugInfoKey.programMeta] = dicts
            } catch {
                NonFatalErrorProvider.shared.debugInfo[DebugInfoKey.programMeta] = error.localizedDescription

                completion(nil, error)
            }
        }

        task.resume()
    }

    func requestorId(completion: @escaping NetworkDictionaryCompletion) {
        guard reachability.currentReachabilityStatus != .notReachable else {
            completion(nil, ResponseError.noInternet)
            return
        }

        let appId = Branding.applicationId

        let request = getRequest(path: "/adobe",
                                 parameters: [ModelConstants.ApplicationIDField: appId,
                                              ModelConstants.PlatformField: ModelConstants.PlatformValue])

        let task = session.dataTask(with: request!) { (data, _, error) in
            guard error == nil else {
                NonFatalErrorProvider.shared.recordUndefinedError(error: error, data: data)
                completion(nil, error)
                return
            }

            do {
                let dict: [String: Any] = try self.processResponse(data: data)
                completion(dict, nil)
            } catch {
                completion(nil, error)
            }
        }

        task.resume()
    }

    func startAuth(shortMediaToken: String,
                   billingZip: String,
                   userId: String,
                   completion: @escaping NetworkDictionaryCompletion) {
        guard reachability.currentReachabilityStatus != .notReachable else {
            return completion(nil, ResponseError.noInternet)
        }

        let request = postRequest(path: "/startAuth",
                                  parameters: [ModelConstants.ShortMediaTokenField: shortMediaToken,
                                               ModelConstants.BillingZIPField: billingZip,
                                               ModelConstants.UserIdField: userId])

        let task = session.dataTask(with: request!) { data, response, error in
            guard error == nil else {
                NonFatalErrorProvider.shared.recordUndefinedError(error: error, data: data)
                print("Received error in startAuth: \(String(describing: error))" +
                      " response: \(String(describing: response))")
                return completion(nil, error)
            }

            do {
                let dict: [String: Any] = try self.processResponse(data: data)
                completion(dict, nil)
            } catch {
                print("Did not get JWT in startAuth: \(error) response: \(String(describing: response))")

                if let response = response as? HTTPURLResponse {
                    if response.statusCode == mediaTokenExpiredCode {
                        print("Short media token expired!")

                        AccessEnablerManager.shared.shortMediaToken = nil

                        let resources = AccessEnablerManager.shared.authorizedResources

                        AccessEnablerManager.shared.login(resources: resources, completion: { (success, error) in
                            if success, let token = AccessEnablerManager.shared.shortMediaToken,
                                let zip = AccessEnablerManager.shared.encryptedZip,
                                let userId = AccessEnablerManager.shared.subscriberId {
                                self.startAuth(shortMediaToken: token,
                                               billingZip: zip,
                                               userId: userId,
                                               completion: completion)
                            } else {
                                completion(nil, error)
                            }
                        })
                        return
                    }
                }

                completion(nil, error)
            }
        }

        task.resume()
    }

    func subscribe(fcmToken: String, authToken: String, completion: @escaping EmptyCompletion) {
        let request = authGetRequest(path: "subscribe", parameters: ["registration_token": fcmToken], token: authToken)

        let task = session.dataTask(with: request!) { (_, _, _) in
            completion()
        }

        task.resume()
    }

    fileprivate func checkAuthStateInResponse(_ response: URLResponse?) throws -> Bool {
        if let response = response as? HTTPURLResponse {
            if response.statusCode == authExpiredCode {
                // reauthorize
                print("JWT expired")

                CoreServices.shared.authorizationProvider.invalidateAuth()

                throw ResponseError.expiredJWT
            }
        }

        return true
    }
}

// MARK: ConcurrencyNetworkService protocol
extension NetworkService: ConcurrencyNetworkServiceProtocol {
    fileprivate enum Concurrency {
        static let location = "Location"
        static let channel = "channel"
        static let expires = "Expires"

        static let password = ""

        static let unauthorizedCode = 401
        static let concurrencyFailureCode = 409

        #if APPSTORE
            static let concurrencybaseURL = "https://streams.adobeprimetime.com/v2"
        #else
            //static let concurrencybaseURL = "https://streams-stage.adobeprimetime.com/v2"
            static let concurrencybaseURL = "https://streams.adobeprimetime.com/v2"
        
        #endif
    }

    fileprivate func requestWithConcurrencyAuth(path: String,
                                                httpMethod: String,
                                                parameters: [String: Any]) -> URLRequest? {
        guard let applicationId = CoreServices.shared.concurrencyProvider.applicationId else {
            return nil
        }

        let requestURLString = Concurrency.concurrencybaseURL + path

        let components = URLComponents(string: requestURLString)

        let url = components?.url
        var request = URLRequest(url: url!)
        request.httpMethod = httpMethod

        let loginString = String(format: "%@:%@", applicationId, Concurrency.password)
        let loginData = loginString.data(using: String.Encoding.utf8)!
        let base64LoginString = loginData.base64EncodedString()

        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")

        if parameters.count > 0 {
            do {
                let data = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
                request.httpBody = data
            } catch {
                print("error creating json")
            }
        }

        return request
    }

    func heartbeat(mvpdId: String, subscriberId: String, sessionId: String, completion: @escaping StringCompletion) {
        let urlString = String(format: "/sessions/%@/%@/%@", mvpdId, subscriberId, sessionId)

        let request = requestWithConcurrencyAuth(path: urlString, httpMethod: "POST", parameters: [:])

        let task = session.dataTask(with: request!) { (_, response, _) in

            guard let result = self.handleConcurrencyResponse(response, completion: completion),
                let expireDate = result[Concurrency.expires] as? String
                else {
                    print("Heartbeat response = \(String(describing: response))")
                    return
            }

            completion(expireDate, nil)
        }

        task.resume()
    }

    func deleteSession(mvpdId: String,
                       subscriberId: String,
                       sessionId: String,
                       completion: @escaping SuccessCompletion) {
        let urlString = String(format: "/sessions/%@/%@/%@", mvpdId, subscriberId, sessionId)

        let request = requestWithConcurrencyAuth(path: urlString, httpMethod: "DELETE", parameters: [:])

        let task = session.dataTask(with: request!) { (_, response, _) in

            guard let httpResponse = response as? HTTPURLResponse,
                httpResponse.statusCode != Concurrency.unauthorizedCode
                else {
                    print("Delete session response = \(String(describing: response))")
                    completion(false, ServerLogicalError.undefined)
                    return
            }

            completion(true, nil)
        }

        task.resume()
    }

    func createSession(mvpdId: String, subscriberId: String, completion: @escaping StringCompletion) {

        guard reachability.currentReachabilityStatus != .notReachable else {
            completion(nil, ResponseError.noInternet)
            return
        }

        let urlString = String(format: "/sessions/%@/%@", mvpdId, subscriberId)

        let request = requestWithConcurrencyAuth(path: urlString, httpMethod: "POST", parameters: [:])

        let task = session.dataTask(with: request!) { (_, response, _) in
            guard let result = self.handleConcurrencyResponse(response, completion: completion),
                let location = result[Concurrency.location] as? String
                else {
                    print("create session response = \(String(describing: response))")
                    return
            }

            completion(location, nil)
        }

        task.resume()
    }

    fileprivate func handleConcurrencyResponse(_ response: URLResponse?,
                                               completion: @escaping StringCompletion) -> [AnyHashable: Any]? {
        guard let httpResponse = response as? HTTPURLResponse else {
            completion(nil, ServerLogicalError.undefined)
            return nil
        }

        if httpResponse.statusCode == Concurrency.concurrencyFailureCode {
            completion(nil, ServerLogicalError.concurrency)
            return nil
        }

        return httpResponse.allHeaderFields
    }
}
