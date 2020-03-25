//
//  ScheduleProvider.swift
//  RootSports
//
//  Created by Sergii Shulga on 8/9/17.
//  Copyright © 2017 Ooyala. All rights reserved.
//

import Foundation

typealias ScheduleCompletion = (_ nodes: [ScheduleNodeModel]?, _ time: Int?, _ error: Error?) -> Void
typealias RegionCompletion = (_ regions: [RegionModel]?, _ error: Error?) -> Void
typealias ConfigCompletion = (_ config: ConfigModel?, _ error: Error?) -> Void

protocol ScheduleNetworkServiceProtocol {
    func schedule(region: String, date: Int?,
                  deviceZip: String?,
                  token: String?,
                  completion: @escaping (_ responseDict: [String: Any]?, _ error: Error?) -> Void)
    func regions(applicationId: String, completion: @escaping (_ regions: [[String: Any]?]?, _ error: Error?) -> Void)
    func currentProgram(channelCode: String, completion: @escaping NetworkDictionaryCompletion)
    func config(_ completion: @escaping NetworkDictionaryCompletion)
}

class ScheduleProvider: BaseProvider {

    private var programs = [ProgramModel]()
    private var scheduleNodes = [ScheduleNodeModel]() // should always be sorted
    private let networkService: ScheduleNetworkServiceProtocol

    private let locationManager: AuthorizationLocationProtocol

    var regions = [RegionModel]()

    var regionCode: String!

    init(networkService: ScheduleNetworkServiceProtocol, locationManager: AuthorizationLocationProtocol) {
        self.networkService = networkService
        self.locationManager = locationManager
    }

    // MARK: - Public

    func todaySchedule(region: String, completion: @escaping ScheduleCompletion) -> [ScheduleNodeModel]? {
        return schedule(forDate: Date(), region: region, completion: completion)
    }

    /// Method for requesting schedule
    ///
    /// - Parameters:
    ///   - date: schedule day can be specified here. if no date is provided method request whole schedule
    ///   - completion: completion block for operation
    /// - Returns: returning current stored schedule nodes
    func schedule(forDate date: Date? = nil,
                  region: String,
                  completion: @escaping ScheduleCompletion) -> [ScheduleNodeModel]? {

        let authProvider = CoreServices.shared.authorizationProvider
        if authProvider.isUserAuthorized, let authToken = authProvider.token {
            // get zip & go to schedule
            locationManager.zipCode { [weak self] zip, _ in
                if let deviceZip = zip {
                    let utf8data = deviceZip.data(using: .utf8)

                    guard let encodedZip = utf8data?.base64EncodedString(options: []) else {
                        completion(nil, 0, ServerLogicalError.deviceZipRegion)
                        return
                    }

                    _ = self?.schedule(forDate: date,
                                       region: region,
                                       deviceZip: encodedZip,
                                       token: authToken,
                                       completion: completion)
                } else {
//                    completion(nil, 0, ServerLogicalError.locationNotDetermined)
                    _ = self?.schedule(forDate: date,
                                       region: region,
                                       deviceZip: nil,
                                       token: nil,
                                       completion: completion)
                }
            }

        } else {
            _ = schedule(forDate: date, region: region, deviceZip: nil, token: nil, completion: completion)
        }

        return nodes(forDate: date)
    }

    /// Method for requesting dynamic schedule
    ///
    /// - Parameters:
    ///   - date: schedule day can be specified here. if no date is provided method request whole schedule
    ///   - deviceZip: device zip
    ///   - completion: completion block for operation
    /// - Returns: returning current stored schedule nodes
    func schedule(forDate date: Date? = nil,
                  region: String,
                  deviceZip: String?,
                  token: String?,
                  completion: @escaping ScheduleCompletion) -> [ScheduleNodeModel]? {
        regionCode = region // regionCode value will be last requested
        networkService.schedule(region: region,
                                date: date?.dayTimestamp,
                                deviceZip: deviceZip,
                                token: token) { responseDict, error in
            if error == nil {

                if let programDicts = responseDict?[ModelConstants.ProgramsField] as? [[String: Any]],
                    let currentTime = responseDict?[ModelConstants.CurrentTimeField] as? Int {

                    var programModels = [ProgramModel]()
                    for dict in programDicts {
                        if let program = ProgramModel(fromDictionary: dict), currentTime < program.end {
                            programModels.append(program)
                        }
                    }
                    self.updateNodes(programs: programModels, forDate: date)

                    completion(self.nodes(forDate: date), currentTime, nil)
                } else {
                    completion(nil, nil, ResponseError.unexpectedFormat)
                }
            } else {
                completion(nil, nil, error)
            }
        }

        return nodes(forDate: date)
    }

    /// Method for requesting regions
    ///
    /// - Parameters:
    ///   - applicationId: application identifier 
    ///   - completion: completion block for operation
    /// - Returns: returning available region(s) for application

    func regions(applicationId: String, completion : @escaping RegionCompletion) {
        networkService.regions(applicationId: applicationId, completion: { (responseArray, error) in

            guard error == nil else {
                completion(nil, error)
                return
            }

            var regionModels = [RegionModel]()
            for dict in responseArray! {
                if let regionDict = dict {
                    if let region = RegionModel(fromDictionary: regionDict) {
                        regionModels.append(region)
                    }
                }
            }

            self.regions = regionModels

            completion(regionModels, nil)
        })
    }

    func currentProgram(channel: String, completion: @escaping StringCompletion) {
        networkService.currentProgram(channelCode: channel) { (response: [String: Any]?, error: Error?) in
            guard error == nil else {
                completion(nil, error)
                return
            }

            if let programCode = response?[ModelConstants.CurrentProgramCodeField] as? String {
                completion(programCode, nil)
            } else {
                completion(nil, ResponseError.unexpectedFormat)
            }
        }
    }

    func config(_ completion: @escaping ConfigCompletion) {
        networkService.config { (responseDict: [String: Any]?, error: Error?) in

            guard error == nil else {
                if let config = NSKeyedUnarchiver.unarchiveObject(withFile: self.pathToConfig) as? ConfigModel {
                    completion(config, error)
                } else {
                    completion(nil, error)
                }
                return
            }

            if let dict = responseDict, let config = ConfigModel(fromDictionary: dict) {
                NSKeyedArchiver.archiveRootObject(config, toFile: self.pathToConfig)
                completion(config, nil)
            } else if let config = NSKeyedUnarchiver.unarchiveObject(withFile: self.pathToConfig
                ) as? ConfigModel {
                completion(config, ResponseError.unexpectedFormat)
            } else {
                completion(nil, ResponseError.unexpectedFormat)
            }
        }
    }

    func regionForChannel(_ channelCode: String) -> RegionModel? {
        for region in regions {
            if region.channelCodes().contains(channelCode) {
                return region
            }
        }

        return nil
    }

    // MARK: - Private
    private var pathToConfig: String {
        guard let libraryPath =
            NSSearchPathForDirectoriesInDomains(.libraryDirectory,
                                                .userDomainMask, true).first else { return "" }
        return (libraryPath as NSString).appendingPathComponent("Config.plist")
    }

    /// Updates scheduleNodes array.
    ///
    /// - Parameters:
    ///   - programs: list of programs to update
    ///   - date: date for update. If no date is provided method updates whole array
    private func updateNodes(programs: [ProgramModel], forDate date: Date? = nil) {

        cleanNodes()

        var newPrograms = programs.sorted(by: {$0.start > $1.start}) // mutating programs
        var joinedPrograms = [[ProgramModel]]() // array of programs array. Programs are divided by start type

        while let program = newPrograms.popLast() {

            if var lastJoin = joinedPrograms.last {
                if lastJoin.first?.start == program.start {
                    // if program have the same time as last joined programs we just add it
                    lastJoin.append(program)
                    joinedPrograms[joinedPrograms.count - 1] = lastJoin
                } else {
                    // if there has been no program with the same time we add new array
                    let newProgramsForNode = [program]
                    joinedPrograms.append(newProgramsForNode)
                }
            } else {
                // the first iteration
                let firstPrograms = [program]
                joinedPrograms.append(firstPrograms)
            }
        }

        for joinedArray in joinedPrograms {
            let node = ScheduleNodeModel(programs: joinedArray)
            scheduleNodes.append(node)
        }

        scheduleNodes.sort { $0.start < $1.start }

    }

    /// Cleans scheduleNodes array
    ///
    /// - Parameter date: date of cleaned nodes. If date is not provided method removes all nodes
    private func cleanNodes(forDate date: Date? = nil) {
        guard let existingDate = date else {
            scheduleNodes.removeAll()
            return
        }

        let nodesForDate = nodes(forDate: existingDate)

        if let firstNode = nodesForDate.first, let lastNode = nodesForDate.last {
            if let firstIndex = scheduleNodes.index(of: firstNode), let lastIndex = scheduleNodes.index(of: lastNode) {
                scheduleNodes.removeSubrange(firstIndex...lastIndex)
            }
        }
    }

    /// Return nodes for specified day
    ///
    /// - Parameter date: day for schedule. If no date is provided returns todays schedule
    /// - Returns: sorted array of schedule nodes
    private func nodes(forDate date: Date?) -> [ScheduleNodeModel] {

        guard !scheduleNodes.isEmpty else {
            return scheduleNodes
        }

        var nodes = [ScheduleNodeModel]()

        let searchingDate = date ?? Date()

        for node in scheduleNodes {
            var calendar = Calendar.current
            calendar.timeZone = TimeZone.current

            let startDate = Date(timeIntervalSince1970: Double(node.start))
            let endDate = Date(timeIntervalSince1970: Double(node.end))

            if calendar.isDate(searchingDate, inSameDayAs: startDate) ||
                calendar.isDate(searchingDate, inSameDayAs: endDate) {
                nodes.append(node)
            }
        }

        return nodes
    }
}
