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
        
        mapView.addOverlay(orsTiles)
        mapView.visibleMapRect = defaultMapRect
        
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

    
    // MARK: User Interaction
    
}

extension MapViewController: SearchResultsViewControllerDelegate {
    
    func searchResultsViewController(controller: SearchResultsViewController, didSelectLocation location: Location) {
        searchController.active = false
        presentRoute(from: UserLocation(), to: location, options: Route.Options(transportationMode: .bicycle), animated: true)
    }
    
}

extension MapViewController: UISearchControllerDelegate {
    
}

extension MapViewController: MKMapViewDelegate {
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        switch overlay {
            
        case let orsTiles as MKTileOverlay where overlay === self.orsTiles:
            let tileOverlayRenderer = MKTileOverlayRenderer(tileOverlay: orsTiles)
            return tileOverlayRenderer
            
        case let route as MKPolyline:
            let routeOverlayRenderer = MKPolylineRenderer(polyline: route)
            routeOverlayRenderer.strokeColor = UIColor.blackColor()
            routeOverlayRenderer.lineWidth = 6
            return routeOverlayRenderer
            
        default:
            fatalError("Could not find renderer for unexpected overlay \(overlay).")
            
        }
    }
    

}

func MKMapRectForCoordinateRegion(region: MKCoordinateRegion) -> MKMapRect
{
    let a = MKMapPointForCoordinate(CLLocationCoordinate2DMake(region.center.latitude + region.span.latitudeDelta / 2, region.center.longitude - region.span.longitudeDelta / 2))
    let b = MKMapPointForCoordinate(CLLocationCoordinate2DMake(region.center.latitude - region.span.latitudeDelta / 2, region.center.longitude + region.span.longitudeDelta / 2))
    return MKMapRectMake(min(a.x, b.x), min(a.y, b.y), abs(a.x - b.x), abs(a.y - b.y));
}
