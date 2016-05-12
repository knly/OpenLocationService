//
//  MapViewController.swift
//  OpenRouteService
//
//  Created by Nils Fischer on 12.05.16.
//  Copyright © 2016 Geographisches Institut der Universität Heidelberg, Abteilung Geoinformatik. All rights reserved.
//

import UIKit
import OpenLocationService
import MapKit


class MapViewController: OLSMapViewController {

    private lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: self.searchResultsViewController)
        searchController.searchResultsUpdater = self.searchResultsViewController
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

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.leftBarButtonItem = MKUserTrackingBarButtonItem(mapView: mapView)
        
        navigationItem.titleView = searchController.searchBar
    }
}

extension MapViewController: SearchResultsViewControllerDelegate {
    
    func searchResultsViewController(controller: SearchResultsViewController, didSelectLocation location: Location) {
        searchController.active = false
        self.presentRoute(from: UserLocation(), to: location, options: Route.Options(transportationMode: .bicycle), animated: true)
    }
    
}
