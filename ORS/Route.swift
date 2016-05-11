//
//  Route.swift
//  uni-hd
//
//  Created by Nils Fischer on 09.12.15.
//  Copyright © 2015 Universität Heidelberg. All rights reserved.
//

import Foundation
import Evergreen
import CoreLocation
import Moya
import PromiseKit
import SWXMLHash


// MARK: - Route

public struct Route: CustomDebugStringConvertible {
    
    public let origin: CLLocationCoordinate2D
    public let destination: CLLocationCoordinate2D
    public let transportationMode: TransportationMode
    public let coordinates: [CLLocationCoordinate2D]
    public let duration: NSTimeInterval?
    public let distance: CLLocationDistance?
    
    public var debugDescription: String {
        return "<Route from \(self.origin) to \(self.destination)>"
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


// MARK: - Route Request

enum RouteRequestError: ErrorType {
    case requestFailed(underlying: ErrorType), parseFailed(underlying: ErrorType), routeNotFound(Route)
}

private let openRouteService = MoyaProvider<OpenRouteService>()

public func requestRouteFromUserLocation(to destination: CLLocationCoordinate2D, transportationMode: TransportationMode) -> Promise<Route> {
    let logger = Evergreen.getLogger("Route.Request")
    logger.debug("Determining user location ...")
    return CLLocationManager.determineUserLocation().recover { error -> Promise<CLLocation> in
        logger.error("Unable to determine user location", error: error)
        return Promise(error: error)
    }.then { userLocation -> Promise<Route> in
        logger.debug("Found user at \(userLocation).")
        return requestRoute(from: userLocation.coordinate, to: destination, transportationMode: transportationMode)
    }
}

public func requestRoute(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D, transportationMode: TransportationMode) -> Promise<Route> {
    let logger = Evergreen.getLogger("Route.Request")
    
    return Promise { fulfill, reject in
        logger.debug("Requesting directions from \(origin) to \(destination) via \(transportationMode)...")
        
        openRouteService.request(.directions(start: origin, end: destination, transportationMode: transportationMode)) { result in
            switch result {
                
            case .Success(let response):
                let xmlString: String
                do {
                    xmlString = try response.mapString()
                } catch {
                    let error = RouteRequestError.parseFailed(underlying: error)
                    logger.error("Invalid response for route request.", error: error)
                    reject(error)
                    return
                }
                let responseXML = SWXMLHash.parse(xmlString)
                let routeCoordinatesXML = responseXML["xls:XLS"]["xls:Response"]["xls:DetermineRouteResponse"]["xls:RouteGeometry"]["gml:LineString"]["gml:pos"]
                guard case .List(let xmlCoordinates) = routeCoordinatesXML else {
                    let error = RouteRequestError.routeNotFound(Route(origin: origin, destination: destination, transportationMode: transportationMode, coordinates: [], duration: nil, distance: nil))
                    logger.error("Route not found.", error: error)
                    reject(error)
                    return
                }
                let routeCoordinates = xmlCoordinates.flatMap({ xmlCoordinate -> CLLocationCoordinate2D? in
                    guard let coordinateStrings = xmlCoordinate.text?.componentsSeparatedByString(" ") else {
                        return nil
                    }
                    guard let latitude = Double(coordinateStrings[1]), let longitude = Double(coordinateStrings[0]) else {
                        return nil
                    }
                    return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                })
                
                let routeSummaryXML = responseXML["xls:XLS"]["xls:Response"]["xls:DetermineRouteResponse"]["xls:RouteSummary"]
                let duration = routeSummaryXML["xls:TotalTime"].element?.text.flatMap({ durationForORSFormattedString($0) })
                let distance = routeSummaryXML["xls:TotalDistance"].element?.attributes["value"].flatMap({ distanceForORSFormattedString($0, unitString: routeSummaryXML["xls:TotalDistance"].element?.attributes["uom"]) })
                
                let route = Route(origin: origin, destination: destination, transportationMode: transportationMode, coordinates: routeCoordinates, duration: duration, distance: distance)
                logger.debug("Found route \(route).")
                fulfill(route)
            case .Failure(let error):
                let error = RouteRequestError.requestFailed(underlying: error)
                logger.warning("Request retrieving route failed.", error: error)
                reject(error)
            }
        }
    }

}
