//
//  CLLocationManager+DetermineUserLocation.swift
//  uni-hd
//
//  Created by Nils Fischer on 08.05.16.
//  Copyright © 2016 Universität Heidelberg. All rights reserved.
//

import CoreLocation
import PromiseKit

extension CLLocationManager {
    
    internal static func determineUserLocation() -> Promise<CLLocation> {
        let locationManagerDelegate = LocationManagerDelegate()
        return locationManagerDelegate.determineUserLocation().then { userLocation -> CLLocation in [locationManagerDelegate]
            return userLocation
        }
    }
    
}

class LocationManagerDelegate: NSObject, CLLocationManagerDelegate {
    
    lazy var locationManager: CLLocationManager = {
        let locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.delegate = self
        return locationManager
    }()
    let pendingPromise = Promise<CLLocation>.pendingPromise()
    
    func determineUserLocation() -> Promise<CLLocation> {
        switch CLLocationManager.authorizationStatus() {

        case .AuthorizedAlways, .AuthorizedWhenInUse:
            locationManager.startUpdatingLocation()

        default:
            pendingPromise.reject(NSError(domain: kCLErrorDomain, code: CLError.Denied.rawValue, userInfo: nil))

        }
        return pendingPromise.promise
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            self.locationManager(manager, didFailWithError: NSError(domain: kCLErrorDomain, code: CLError.LocationUnknown.rawValue, userInfo: nil))
            return
        }
        pendingPromise.fulfill(location)
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        pendingPromise.reject(error)
        locationManager.stopUpdatingLocation()
    }

}
