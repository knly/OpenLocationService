//
//  ViewController.swift
//  ORS
//
//  Created by Nils Fischer on 11.05.16.
//  Copyright © 2016 Geographisches Institut der Universität Heidelberg, Abteilung Geoinformatik. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController {

    @IBOutlet var mapView: MKMapView!
    
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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.addOverlay(orsTiles)
        mapView.visibleMapRect = defaultMapRect
    }
    
}

extension MapViewController: MKMapViewDelegate {
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        switch overlay {
            
        case let orsTiles as MKTileOverlay where overlay === self.orsTiles:
            let tileOverlayRenderer = MKTileOverlayRenderer(tileOverlay: orsTiles)
            return tileOverlayRenderer
            
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
