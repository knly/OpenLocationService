//
//  ViewController.swift
//  ORS
//
//  Created by Nils Fischer on 11.05.16.
//  Copyright © 2016 Geographisches Institut der Universität Heidelberg, Abteilung Geoinformatik. All rights reserved.
//

import UIKit
import MapKit
import PromiseKit
import Evergreen


public class OLSMapViewController: UIViewController {

    @IBOutlet public var mapView: MKMapView!
    
    private var routeOverlay: MKOverlay?
    private var selectedLocationAnnotation: LocationAnnotation?
    
    private let locationManager = CLLocationManager()
    
    private lazy var longPressGestureRecognizer: UIGestureRecognizer = {
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPress(_:)))
        return gestureRecognizer
    }()
    
    
    private let orsTiles: MKTileOverlay = {
        let tileOverlay = MKTileOverlay(URLTemplate: Constants.ORSTilesURLTemplate)
        tileOverlay.tileSize = CGSize(width: 512, height: 512)
        tileOverlay.canReplaceMapContent = true
        return tileOverlay
    }()
    
    private let defaultMapRect: MKMapRect = {
        let region = MKCoordinateRegionMakeWithDistance(CLLocationCoordinate2DMake(49.4085, 8.68685), 2000, 2000)
        return MKMapRectForCoordinateRegion(region)
    }()

    private let displayEdgePadding: UIEdgeInsets = UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50)

    override public func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.showsUserLocation = true
        mapView.addOverlay(orsTiles)
        mapView.visibleMapRect = defaultMapRect
        
        mapView.addGestureRecognizer(longPressGestureRecognizer)
    }
    
    public func presentRoute(from origin: Locatable, to destination: Locatable, options: Route.Options, animated: Bool) {
        if CLLocationManager.authorizationStatus() == .NotDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else {
            Route.request(from: origin, to: destination, options: options).then { route -> Void in
                var routeCoordinates = route.waypoints
                if routeCoordinates.count > 0 {
                    if let previousRouteOverlay = self.routeOverlay {
                        self.mapView.removeOverlay(previousRouteOverlay)
                    }
                    let routeOverlay = MKPolyline(coordinates: &routeCoordinates, count: routeCoordinates.count)
                    self.mapView.addOverlay(routeOverlay)
                    self.routeOverlay = routeOverlay
                    self.mapView.setVisibleMapRect(routeOverlay.boundingMapRect, edgePadding: self.displayEdgePadding, animated: animated)
                }
            }
        }
    }

    private func clearSelectedLocationAnnotation(animated animated: Bool) {
        if let selectedLocationAnnotation = self.selectedLocationAnnotation {
            mapView.removeAnnotation(selectedLocationAnnotation)
        }
    }
    
    private func annotate(location: MapAnnotation, animated: Bool) -> LocationAnnotation {
        let annotation = LocationAnnotation(location: location, animatePresentation: animated)
        mapView.addAnnotation(annotation)
        return annotation
    }
    
    // MARK: User Interaction
    
    @objc private func longPress(gestureRecognizer: UILongPressGestureRecognizer) {
        guard case .Began = gestureRecognizer.state else {
            return
        }
        let location = SelectedLocation(coordinate: mapView.convertPoint(gestureRecognizer.locationInView(mapView), toCoordinateFromView: mapView))
        self.clearSelectedLocationAnnotation(animated: true)
        let selectedLocationAnnotation = self.annotate(location, animated: true)
        self.selectedLocationAnnotation = selectedLocationAnnotation
        
        let logger = Evergreen.getLogger("AccessibilityAnalysis")
        openLocationService.request(.accessibility(position: location.coordinate, transportationMode: .bicycle, time: 10*60, interval: 5*60)) { result in
            switch result {
                
            case .Success(let response):
                do {
                    try response.filterSuccessfulStatusCodes()
                } catch {
                    logger.error("Invalid status code \(response.statusCode)", error: error)
                    return
                }
                let accessibleArea: AccessibleArea
                do {
                    accessibleArea = try response.mapAccessibleArea(around: location.coordinate)
                    logger.debug("Found accessibility \(accessibleArea).")
                } catch {
                    logger.error("Unable to parse response to geocoded locations.", error: error)
                    return
                }
                
                for isochrone in accessibleArea.isochrones {
                    var borderCoordinates = isochrone.coordinates
                    let border = MKPolygon(coordinates: &borderCoordinates, count: borderCoordinates.count)
                    self.mapView.addOverlay(border)
                }
                
            case .Failure(let error):
                print(error)
            }
        }
    }
    
}

class LocationAnnotation: NSObject, MKAnnotation {
    
    let location: MapAnnotation
    let animatePresentation: Bool
    
    init(location: MapAnnotation, animatePresentation: Bool) {
        self.location = location
        self.animatePresentation = animatePresentation
    }
    
    var coordinate: CLLocationCoordinate2D { return location.coordinate }
    var title: String? { return location.title }
    var subtitle: String? { return location.subtitle }
    
}


extension NSUserDefaults {
    
    var preferredTransportationMode: TransportationMode? {
        get {
            guard let preferredTransportationModeRawValue = (self.valueForKey(Constants.UserDefaultsKey.preferredTransportationMode) as? NSNumber)?.integerValue,
                preferredTransportationMode = TransportationMode(segmentIndex: preferredTransportationModeRawValue) else {
                    return nil
            }
            return preferredTransportationMode
        }
        set {
            self.setValue(newValue?.segmentIndex, forKey: Constants.UserDefaultsKey.preferredTransportationMode)
        }
    }
    
}

extension TransportationMode {
    
    init?(segmentIndex: Int) {
        switch segmentIndex {
        case 0: self = .pedestrian
        case 1: self = .bicycle
        case 2: self = .wheelchair
        case 3: self = .car
        default: return nil
        }
    }
    
    var segmentIndex: Int {
        switch self {
        case .pedestrian: return 0
        case .bicycle: return 1
        case .wheelchair: return 2
        case .car: return 3
        }
    }
    
}



extension OLSMapViewController: MKMapViewDelegate {
    
     public func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        switch overlay {
            
        case let orsTiles as MKTileOverlay where overlay === self.orsTiles:
            let tileOverlayRenderer = MKTileOverlayRenderer(tileOverlay: orsTiles)
            return tileOverlayRenderer
            
        case let route as MKPolyline:
            let overlayRenderer = MKPolylineRenderer(polyline: route)
            overlayRenderer.strokeColor = mapView.tintColor
            overlayRenderer.lineWidth = 6
            return overlayRenderer
            
        case let accessibleArea as MKPolygon:
            let overlayRenderer = MKPolygonRenderer(polygon: accessibleArea)
            overlayRenderer.strokeColor = mapView.tintColor
            overlayRenderer.lineWidth = 3
            overlayRenderer.fillColor = mapView.tintColor.colorWithAlphaComponent(0.2)
            return overlayRenderer
            
        default:
            fatalError("Could not find renderer for unexpected overlay \(overlay).")
            
        }
    }
    
     public func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        switch annotation {
            
        case let locationAnnotation as LocationAnnotation:
            let annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier("LocationAnnotation") as? MKPinAnnotationView ?? MKPinAnnotationView(annotation: annotation, reuseIdentifier: "LocationAnnotation")
            annotationView.annotation = annotation
            annotationView.animatesDrop = locationAnnotation.animatePresentation
            annotationView.canShowCallout = true
            
            let location = locationAnnotation.location
            
            let routeButton = RouteButton(location: location)
            annotationView.leftCalloutAccessoryView = routeButton

            return annotationView
            
        default: return nil
            
        }
    }
    
     public func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        switch (view.annotation, control) {
        
        case let (locationAnnotation as LocationAnnotation, routeButton as RouteButton):
            presentRoute(from: UserLocation(), to: locationAnnotation.location, options: Route.Options(transportationMode: routeButton.transportationMode), animated: true)
            
        default: return
            
        }
    }

}

func MKMapRectForCoordinateRegion(region: MKCoordinateRegion) -> MKMapRect
{
    let a = MKMapPointForCoordinate(CLLocationCoordinate2DMake(region.center.latitude + region.span.latitudeDelta / 2, region.center.longitude - region.span.longitudeDelta / 2))
    let b = MKMapPointForCoordinate(CLLocationCoordinate2DMake(region.center.latitude - region.span.latitudeDelta / 2, region.center.longitude + region.span.longitudeDelta / 2))
    return MKMapRectMake(min(a.x, b.x), min(a.y, b.y), abs(a.x - b.x), abs(a.y - b.y));
}
