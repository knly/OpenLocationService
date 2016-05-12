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

class MapViewController: UIViewController {

    @IBOutlet private var mapView: MKMapView!
    
    private var routeOverlay: MKOverlay?
    private var selectedLocationAnnotation: LocationAnnotation?
    
    private let locationManager = CLLocationManager()
    
    private lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: self.searchResultsViewController)
        searchController.searchResultsUpdater = self.searchResultsViewController
        searchController.delegate = self
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.dimsBackgroundDuringPresentation = false
        self.definesPresentationContext = true
        return searchController
    }()
    
    private lazy var longPressGestureRecognizer: UIGestureRecognizer = {
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPress(_:)))
        return gestureRecognizer
    }()
    
    private lazy var searchResultsViewController: SearchResultsViewController = {
        let viewController = SearchResultsViewController(style: .Plain)
        viewController.delegate = self
        return viewController
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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.showsUserLocation = true
        mapView.addOverlay(orsTiles)
        mapView.visibleMapRect = defaultMapRect
        
        mapView.addGestureRecognizer(longPressGestureRecognizer)
        
        navigationItem.titleView = searchController.searchBar
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        let kip = CLLocationCoordinate2D(latitude: 49.416405, longitude: 8.671716)
        presentRoute(from: UserLocation(), to: kip, options: Route.Options(transportationMode: .bicycle), animated: true)
    }
    
    private func presentRoute(from origin: Locatable, to destination: Locatable, options: Route.Options, animated: Bool) {
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
    }
    
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

protocol MapAnnotation: Location {
    
    var title: String? { get }
    var subtitle: String? { get }
    
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

extension MapViewController: SearchResultsViewControllerDelegate {
    
    func searchResultsViewController(controller: SearchResultsViewController, didSelectLocation location: Location) {
        searchController.active = false
        presentRoute(from: UserLocation(), to: location, options: Route.Options(transportationMode: .bicycle), animated: true)
    }
    
}

extension MapViewController: UISearchControllerDelegate {
    
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



extension MapViewController: MKMapViewDelegate {
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        switch overlay {
            
        case let orsTiles as MKTileOverlay where overlay === self.orsTiles:
            let tileOverlayRenderer = MKTileOverlayRenderer(tileOverlay: orsTiles)
            return tileOverlayRenderer
            
        case let route as MKPolyline:
            let routeOverlayRenderer = MKPolylineRenderer(polyline: route)
            routeOverlayRenderer.strokeColor = UIColor.brandColor()
            routeOverlayRenderer.lineWidth = 6
            return routeOverlayRenderer
            
        default:
            fatalError("Could not find renderer for unexpected overlay \(overlay).")
            
        }
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
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
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
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
