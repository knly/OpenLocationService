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


internal enum OpenRouteService: Moya.TargetType {
    case directions(start: CLLocationCoordinate2D, end: CLLocationCoordinate2D, transportationMode: TransportationMode)
    
    var baseURL: NSURL { return NSURL(string: "http://openls.geog.uni-heidelberg.de")! }
    
    var path: String {
        switch self {
        case .directions: return "/route"
        }
    }
    
    var method: Moya.Method { return .GET }
    
    var parameters: [String : AnyObject]? {
        switch self {
        case .directions(start: let start, end: let end, transportationMode: let transportationMode):
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
        }
    }
    
    var sampleData: NSData {
        switch self {
        case .directions(start: let start, end: let end, _):
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
        }
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
