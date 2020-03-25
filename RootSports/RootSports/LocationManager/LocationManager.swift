//
//  LocationManager.swift
//  RootSports
//
//  Created by Artak on 8/9/17.
//  Copyright © 2017 Ooyala. All rights reserved.
//

import CoreLocation

typealias LocationZipHandler = ((_ zipCode: String?, _ error: Error?) -> Void)

enum LocationManagerState {
    case notRunning
    case running
    case noZip
    case ready
}

class LocationError: Error {

    enum LocationErrorCode {
        case serviceDisabled
        case invalidGeocode
        case managerError
    }

    let code: LocationErrorCode

    init(code: LocationErrorCode) {
        self.code = code
    }
}

class LocationManager: NSObject {

    fileprivate var handler: LocationZipHandler? // calls on every location update, until locationManager works
    fileprivate var completion: LocationZipHandler? // calls only once

    fileprivate let locationManager = CLLocationManager()

    fileprivate let reachability = Reachability()

    fileprivate var zipCode: String?

    fileprivate var startedUpdatesDate: Date?

    fileprivate var state: LocationManagerState = .notRunning {
        didSet {
            if state != .ready {
                zipCode = nil
            }
        }
    }

    func startLocationManager(completionHandler: LocationZipHandler?) {

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        handler = completionHandler

        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            startedUpdatesDate = Date()
            locationManager.startUpdatingLocation()
            state = .running
        default: //.denied, .restricted
            let error = LocationError(code: .serviceDisabled)
            notify(zip: nil, error: error)
        }
    }

    func stopUpdates() {
        locationManager.stopUpdatingLocation()
        locationManager.delegate = nil
        state = .notRunning
    }

    fileprivate func notify(zip: String?, error: Error?) {

        if let completion = completion {
            completion(zip, error)
            self.completion = nil
        }

        if let handler = handler {
            handler(zip, error)
        } else {
            stopUpdates()
        }
    }
}

extension LocationManager: AuthorizationLocationProtocol {
    func zipCode(completion: @escaping LocationZipHandler) {
        switch state {
        case .notRunning:
            self.completion = completion
            startLocationManager(completionHandler: nil)
        case .running:
            self.completion = completion
        case .noZip:
            let error = LocationError(code: .invalidGeocode)
            completion(nil, error)
        case .ready:
            if let zip = zipCode {
                completion(zip, nil)
            } else {
                let error = LocationError(code: .invalidGeocode)
                completion(nil, error)
            }
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {

        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            startedUpdatesDate = Date()
            locationManager.startUpdatingLocation()
            state = .running
        case .restricted, .denied:
            let error = LocationError(code: .serviceDisabled)
            notify(zip: nil, error: error)
        default: // .notDetermined
            break
        }

    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let error = LocationError(code: .managerError)
        notify(zip: nil, error: error)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if manager.location == nil {
            return
        }

        if let location = manager.location,
            let initialDate = startedUpdatesDate,
            location.timestamp > initialDate - CoreServices.shared.config.deviceZipTimeout {

            guard reachability?.currentReachabilityStatus != .notReachable else {
                self.notify(zip: nil, error: ResponseError.noInternet)
                return
            }
            print("Received location \(location)")
            self.locationManager.stopUpdatingLocation()
            self.locationManager.delegate = nil

            CLGeocoder().reverseGeocodeLocation(location,
                                                completionHandler: { [unowned self] placemarks, error in
                // for local qa builds
//                #if !APPSTORE && !DEBUG
//                    self.zipCode = "94102"
//                    self.state = .ready
//                    self.notify(zip: self.zipCode, error: nil)
//                    return
//                #endif

                guard error == nil, let code = placemarks?.first?.postalCode  else {
                    self.state = .noZip
                    let error = LocationError(code: .invalidGeocode)
                    self.notify(zip: nil, error: error)
                    return
                }

                self.zipCode = code
                self.state = .ready
                self.notify(zip: code, error: nil)

                if CoreServices.shared.config.deviceZipTimeout > 0 {
                    Timer.scheduledTimer(timeInterval: CoreServices.shared.config.deviceZipTimeout,
                                         target: self,
                                         selector: #selector(self.invalidateZip),
                                         userInfo: nil,
                                         repeats: false)
                }
            })
        }
    }

    @objc private func invalidateZip() {
        print("Invalidating zip")
        state = .notRunning
        zipCode = nil
        startedUpdatesDate = nil
    }

}
