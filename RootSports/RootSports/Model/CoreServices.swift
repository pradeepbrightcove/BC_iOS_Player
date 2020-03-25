//
//  CoreServices.swift
//  RootSports
//
//  Created by Sergii Shulga on 8/10/17.
//  Copyright © 2017 Ooyala. All rights reserved.
//

import Foundation

enum ServerLogicalError: Int, Error {
    case undefined
    case appSecurity = 1
    case authNFailure = 2
    case authZFailure = 3
    case noBillingZip = 4
    case concurrency = 5
    case deviceZipRegion = 6
    case billingZipAuthorization = 7
    case deviceZipProduct = 8
    case noPrograms = 13
    case drmRestricted = 14
    case incorrectZip = 15
    case locationNotDetermined = 16
    case billingZipProduct = 81
    case noProgramsOnAir = 404
    case streamUnavailable = 424
}

class CoreServices {
    static let shared = CoreServices()

    let scheduleProvider: ScheduleProvider
    let authorizationProvider: AuthorizationProvider
    let concurrencyProvider: ConcurrencyProvider
    let firebaseService = FirebaseService()

    private let networkService = NetworkService()
    private let locationManager = LocationManager()

    var config: ConfigModel = ConfigModel()

    init() {
        self.scheduleProvider = ScheduleProvider(networkService: self.networkService,
                                                 locationManager: self.locationManager)
        self.authorizationProvider = AuthorizationProvider(networkService: self.networkService,
                                                           locationManager: self.locationManager)
        self.concurrencyProvider = ConcurrencyProvider(networkService: self.networkService)
    }

    static func errorForCode(_ code: ServerLogicalError) -> ErrorModel {
        for error in CoreServices.shared.config.errors where error.code == code.rawValue {
            return error
        }

        if code == .appSecurity {
            let error = ErrorModel()

            error.message = ModelConstants.unsecureErrorMessage
            error.title = ModelConstants.unsecureErrorTitle
            error.code = 1

            return error
        }

        return ErrorModel()
    }
}
