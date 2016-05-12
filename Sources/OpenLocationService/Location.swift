//
//  Location.swift
//  Pods
//
//  Created by Nils Fischer on 12.05.16.
//
//

import Foundation
import CoreLocation
import MapKit
import Evergreen
import PromiseKit

public protocol Locatable {
    
    func locate() -> Promise<Location>
    
}

public protocol Location: Locatable {
    
    var coordinate: CLLocationCoordinate2D { get }
    
}

public extension Location {
    func locate() -> Promise<Location> {
        return Promise(self)
    }
}


public struct UserLocation: Locatable {
    
    public init() {}
    
    public func locate() -> Promise<Location> {
        let logger = Evergreen.getLogger("Location.UserLocation")
        logger.debug("Determining user location ...")
        return CLLocationManager.determineUserLocation().then { userLocation -> Promise<Location> in
            logger.debug("Found user at \(userLocation).")
            return Promise(userLocation)
            }.recover { error -> Promise<Location> in
                logger.error("Unable to determine user location", error: error)
                return Promise(error: error)
        }
    }
    
}


extension CLLocationCoordinate2D: Location {
    public var coordinate: CLLocationCoordinate2D { return self }
}

extension CLLocation: Location {}

extension MKMapItem: Location {
    public var coordinate: CLLocationCoordinate2D { return self.placemark.coordinate }
}

struct SelectedLocation: Location, MapAnnotation {
    
    let coordinate: CLLocationCoordinate2D
    
    var title: String? {
        return NSLocalizedString("Selected Location", comment: "")
    }
    
    var subtitle: String? {
        return nil
    }
    
}
