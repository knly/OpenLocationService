//
//  OpenRouteService.swift
//  ORS
//
//  Created by Nils Fischer on 11.05.16.
//  Copyright © 2016 Geographisches Institut der Universität Heidelberg, Abteilung Geoinformatik. All rights reserved.
//

import Foundation
import Moya
import CoreLocation
import SWXMLHash

internal let openLocationService = MoyaProvider<OpenLocationService>()

internal enum OpenLocationService: Moya.TargetType {
    case route(start: CLLocationCoordinate2D, end: CLLocationCoordinate2D, transportationMode: TransportationMode)
    case geocode(freeFormAddress: String, maxResponses: Int)
    
    var baseURL: NSURL { return NSURL(string: "http://openls.geog.uni-heidelberg.de")! }
    
    var path: String {
        switch self {
        case .route: return "/route"
        case .geocode: return "/geocode"
        }
    }
    
    var method: Moya.Method { return .GET }
    
    var parameters: [String : AnyObject]? {
        switch self {
        case .route(start: let start, end: let end, transportationMode: let transportationMode):
            return [
                "start": "\(start.longitude),\(start.latitude)",
                "end": "\(end.longitude),\(end.latitude)",
                "via": "",
                "lang": "de",
                "distunit": "KM",
                "routepref": {
                    switch transportationMode {
                    case .pedestrian: return "Pedestrian"
                    case .bicycle: return "Bicycle"
                    case .wheelchair: return "Wheelchair"
                    case .car: return "Car"
                    }
                }(),
                "weighting": "Recommended",
                "avoidAreas": "",
                "useTMC": "false",
                "noMotorways": "false",
                "noTollways": "false",
                "noUnpavedroads": "false",
                "noSteps": "false",
                "noFerries": "false",
                "instructions": "false",
            ]
        case .geocode(freeFormAddress: let freeFormAddress, maxResponses: let maxResponses):
            return [
                "FreeFormAdress": freeFormAddress,
                "MaxResponse": maxResponses,
            ]
        }
    }
    
    var sampleData: NSData {
        switch self {
        case .route(start: let start, end: let end, _):
            return ("<?xml version=\"1.0\" encoding=\"UTF-8\"?>" +
                "<xls:XLS xmlns:xls=\"http://www.opengis.net/xls\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:gml=\"http://www.opengis.net/gml\" version=\"1.1\" xsi:schemaLocation=\"http://www.opengis.net/xls http://schemas.opengis.net/ols/1.1.0/RouteService.xsd\">" +
                "<xls:ResponseHeader xsi:type=\"xls:ResponseHeaderType\"/>" +
                "<xls:Response xsi:type=\"xls:ResponseType\" requestID=\"123456789\" version=\"1.1\" numberOfResponses=\"1\">" +
                "<xls:DetermineRouteResponse xsi:type=\"xls:DetermineRouteResponseType\">" +
                "<xls:RouteSummary>" +
                "<xls:TotalTime>PT6H38M52S</xls:TotalTime>" +
                "<xls:TotalDistance uom=\"KM\" value=\"84.0\"/>" +
                "<xls:ActualDistance uom=\"KM\" value=\"51.0\"/>" +
                "<xls:BoundingBox srsName=\"EPSG:4326\">" +
                "<gml:pos>\(min(start.longitude, end.longitude)) \(min(start.latitude, end.latitude))</gml:pos>" +
                "<gml:pos>\(max(start.longitude, end.longitude)) \(max(start.latitude, end.latitude))</gml:pos>" +
                "</xls:BoundingBox>" +
                "</xls:RouteSummary>" +
                "<xls:RouteGeometry>" +
                "<gml:LineString srsName=\"EPSG:4326\">" +
                "<gml:pos>\(start.longitude) \(start.latitude)</gml:pos>" +
                "<gml:pos>\(end.longitude) \(end.latitude)</gml:pos>" +
                "</gml:LineString>" +
                "</xls:RouteGeometry>" +
                "</xls:DetermineRouteResponse>" +
                "</xls:Response>" +
                "</xls:XLS>").dataUsingEncoding(NSUTF8StringEncoding)!
        case .geocode(freeFormAddress: let freeFormAddress, maxResponses: let maxResponses):
            return ("<?xml version=\"1.0\" encoding=\"UTF-8\"?>" +
                "<xls:XLS xmlns:xls=\"http://www.opengis.net/xls\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:gml=\"http://www.opengis.net/gml\" version=\"1.1\" xsi:schemaLocation=\"http://www.opengis.net/xls http://schemas.opengis.net/ols/1.1.0/LocationUtilityService.xsd\">" +
                "<xls:ResponseHeader xsi:type=\"xls:ResponseHeaderType\"/>" +
                "<xls:Response xsi:type=\"xls:ResponseType\" requestID=\"123456789\" version=\"1.1\" numberOfResponses=\"1\">" +
                "<xls:GeocodeResponse xsi:type=\"xls:GeocodeResponseType\">" +
                "<xls:GeocodeResponseList numberOfGeocodedAddresses=\"1\">" +
                "<xls:GeocodedAddress>" +
                "<gml:Point>" +
                "<gml:pos srsName=\"EPSG:4326\">7.0457339 50.6495327</gml:pos>" +
                "</gml:Point>" +
                "<xls:Address countryCode=\"\">" +
                "<xls:StreetAddress>" +
                "<xls:Street officialName=\"Meckenheimer Allee\"/>" +
                "</xls:StreetAddress>" +
                "<xls:Place type=\"Country\">Deutschland</xls:Place>" +
                "<xls:Place type=\"CountrySubdivision\">Nordrhein-Westfalen</xls:Place>" +
                "<xls:Place type=\"CountrySecondarySubdivision\">Regierungsbezirk Köln</xls:Place>" +
                "<xls:Place type=\"Municipality\">Bonn</xls:Place>" +
                "<xls:PostalCode>53125</xls:PostalCode>" +
                "</xls:Address>" +
                "<xls:GeocodeMatchCode accuracy=\"1.0\"/>" +
                "</xls:GeocodedAddress>" +
                "</xls:GeocodeResponseList>" +
                "</xls:GeocodeResponse>" +
                "</xls:Response>" +
                "</xls:XLS>").dataUsingEncoding(NSUTF8StringEncoding)!
        }
    }
}

enum RouteRequestError: ErrorType {
    case routeNotFound
}

extension Moya.Response {
    
    func mapRoute(from origin: Location, to destination: Location, options: Route.Options) throws -> Route {
        let xmlString = try self.mapString()
        let responseXML = SWXMLHash.parse(xmlString)
        let waypointsXML = responseXML["xls:XLS"]["xls:Response"]["xls:DetermineRouteResponse"]["xls:RouteGeometry"]["gml:LineString"]["gml:pos"]
        guard case .List(let xmlCoordinates) = waypointsXML else {
            throw RouteRequestError.routeNotFound
        }
        let waypoints = xmlCoordinates.flatMap({ xmlCoordinate -> CLLocationCoordinate2D? in
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
        let route = Route(origin: origin, destination: destination, options: options, waypoints: waypoints, duration: duration, distance: distance)
        return route
    }
}


/// Converts from "PT6H38M52S" to `NSTimeInterval`
func durationForORSFormattedString(string: String) -> NSTimeInterval? {
    var components = string.componentsSeparatedByString("PT")
    guard components.count == 2 else { return nil }
    var string = components[1]
    components = string.componentsSeparatedByString("H")
    guard components.count <= 2 else { return nil }
    let hours: Int
    if components.count == 2 {
        hours = Int(components[0]) ?? 0
        string = components[1]
    } else {
        hours = 0
        string = components[0]
    }
    components = string.componentsSeparatedByString("M")
    guard components.count <= 2 else { return nil }
    let minutes: Int
    if components.count == 2 {
        minutes = Int(components[0]) ?? 0
        string = components[1]
    } else {
        minutes = 0
        string = components[0]
    }
    components = string.componentsSeparatedByString("S")
    guard components.count <= 2 else { return nil }
    let seconds: Int
    if components.count == 2 {
        seconds = Int(components[0]) ?? 0
        string = components[1]
    } else {
        seconds = 0
        string = components[0]
    }
    guard string == "" else { return nil }
    let duration = NSTimeInterval(seconds + minutes * 60 + hours * 60 * 60)
    guard duration > 0 else { return nil }
    return duration
}

/// Converts from "84.0" in unit given by `unitString` to `CLLocationDistance`
func distanceForORSFormattedString(string: String, unitString: String?) -> CLLocationDistance? {
    if let unitString = unitString {
        guard unitString == "KM" else { return nil }
    }
    guard let kms = Double(string) else { return nil }
    let distance = kms * 1000
    guard distance > 0 else { return nil }
    return distance
}


extension Moya.Response {
    
    func mapGeocodedLocations() throws -> [GeocodedLocation] {
        let xmlString = try self.mapString()
        let responseXML = SWXMLHash.parse(xmlString)
        let geocodedLocationsXML = responseXML["xls:XLS"]["xls:Response"]["xls:GeocodeResponse"]["xls:GeocodeResponseList"]["xls:GeocodedAddress"]
        if case .XMLError(let error) = geocodedLocationsXML {
            throw error
        }
        return geocodedLocationsXML.flatMap({ geocodedLocationXML -> GeocodedLocation? in
            guard let coordinateStrings = geocodedLocationXML["gml:Point"]["gml:pos"].element?.text?.componentsSeparatedByString(" ") else {
                return nil
            }
            guard let latitude = Double(coordinateStrings[1]), let longitude = Double(coordinateStrings[0]) else {
                return nil
            }
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let addressXML = geocodedLocationXML["xls:Address"]
            var isoCountryCode: String? = nil
            if let parsedISOCountryCode = addressXML.element?.attributes["countryCode"] {
                isoCountryCode = parsedISOCountryCode
            }
            var street: String? = nil
            if let parsedStreet = addressXML["xls:StreetAddress"]["xls:Street"].element?.attributes["officialName"] {
                street = parsedStreet
            }
            if let parsedBuildingNumber = addressXML["xls:StreetAddress"]["xls:Building"].element?.attributes["number"], parsedStreet = street {
                street = [ parsedStreet, parsedBuildingNumber ].joinWithSeparator(" ")
            }
            var city: String? = nil
            if let parsedCity = try? addressXML["xls:Place"].withAttr("type", "Municipality").element?.text {
                city = parsedCity
            }
            var postalCode: String? = nil
            if let parsedPostalCode = addressXML["xls:PostalCode"].element?.text {
                postalCode = parsedPostalCode
            }
            var state: String? = nil
            if let parsedState = try? addressXML["xls:Place"].withAttr("type", "CountrySubdivision").element?.text {
                state = parsedState
            }
            var country: String? = nil
            if let parsedCountry = try? addressXML["xls:Place"].withAttr("type", "Country").element?.text {
                country = parsedCountry
            }
            let address = Address(street: street ?? "", city: city ?? "", postalCode: postalCode ?? "", state: state ?? "", country: country ?? "", ISOCountryCode: isoCountryCode ?? "")
            return GeocodedLocation(coordinate: coordinate, address: address)
        })
    }
    
}

struct GeocodedLocation: Location {
    
    let coordinate: CLLocationCoordinate2D
    let address: Address
    
}


import Contacts

struct Address {
    
    let street: String
    let city: String
    let postalCode: String
    let state: String
    let country: String
    let ISOCountryCode: String
    
    var localizedDescription: String {
        let formatter = CNPostalAddressFormatter()
        let postalAddress = CNMutablePostalAddress()
        postalAddress.street = street
        postalAddress.city = city
        postalAddress.postalCode = postalCode
        postalAddress.state = state
        postalAddress.country = country
        postalAddress.ISOCountryCode = ISOCountryCode
        return formatter.stringFromPostalAddress(postalAddress)
    }
    
}
