//
//  Route.swift
//  uni-hd
//
//  Created by Nils Fischer on 09.12.15.
//  Copyright © 2015 Universität Heidelberg. All rights reserved.
//

import Foundation
import Evergreen
import MapKit
import Moya
import PromiseKit


// MARK: - Route

public protocol Locatable {
    
    func locate() -> Promise<Location>
    
}

public struct UserLocation: Locatable {
    
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

public protocol Location: Locatable {
    
    var coordinate: CLLocationCoordinate2D { get }

}

extension Location {
    public func locate() -> Promise<Location> {
        return Promise(self)
    }
}

extension CLLocationCoordinate2D: Location {
    public var coordinate: CLLocationCoordinate2D { return self }
}

extension CLLocation: Location {}

extension MKMapItem: Location {
    public var coordinate: CLLocationCoordinate2D { return self.placemark.coordinate }
}


public struct Route: CustomDebugStringConvertible {
    
    public let origin: Location
    public let destination: Location
    public let options: Options
    
    public struct Options {
        
        public let transportationMode: TransportationMode
        
    }
    
    public let waypoints: [CLLocationCoordinate2D]
    public let duration: NSTimeInterval?
    public let distance: CLLocationDistance?
    
    public var debugDescription: String {
        return "<Route from \(self.origin) to \(self.destination)>"
    }
    
    public static func request(from origin: Locatable, to destination: Locatable, options: Options) -> Promise<Route> {
        let logger = Evergreen.getLogger("Route.Request")
        logger.debug("Requesting route from \(origin) to \(destination)...")
        
        return when(origin.locate(), destination.locate()).then { origin, destination in
            logger.debug("Requesting route from \(origin) to \(destination)...")
            
            return Promise { fulfill, reject in
                openLocationService.request(.route(start: origin.coordinate, end: destination.coordinate, transportationMode: options.transportationMode)) { result in
                    switch result {
                        
                    case .Success(let response):
                        do {
                            try response.filterSuccessfulStatusCodes()
                        } catch {
                            logger.error("Invalid status code \(response.statusCode).", error: error)
                            reject(error)
                            return
                        }
                        do {
                            let route = try response.mapRoute(from: origin, to: destination, options: options)
                            logger.debug("Found route \(route).")
                            fulfill(route)
                            return
                        } catch {
                            logger.error("Unable to parse route response.", error: error)
                            reject(error)
                            return
                        }
                        
                    case .Failure(let error):
                        logger.warning("Failed requesting route.", error: error)
                        reject(error)
                        return
                    }
                }
            }
        }
    }

}


// MARK: - Transportation Mode

public enum TransportationMode {
    case pedestrian, bicycle, wheelchair, car
    
    var localizedTitle: String {
        switch self {
        case .pedestrian: return NSLocalizedString("Zu Fuß", comment: "")
        case .bicycle: return NSLocalizedString("Fahrrad", comment: "")
        case .wheelchair: return NSLocalizedString("Rollstuhl", comment: "")
        case .car: return NSLocalizedString("Auto", comment: "")
        }
    }
}
