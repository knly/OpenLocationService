//
//  SearchViewController.swift
//  ORS
//
//  Created by Nils Fischer on 11.05.16.
//  Copyright © 2016 Geographisches Institut der Universität Heidelberg, Abteilung Geoinformatik. All rights reserved.
//

import UIKit
import Evergreen
import Moya
import OpenLocationService

protocol SearchResultsViewControllerDelegate {
    
    func searchResultsViewController(controller: SearchResultsViewController, didSelectLocation location: Location)
    
}

class SearchResultsViewController: UITableViewController {
    
    var delegate: SearchResultsViewControllerDelegate?
    
    private var locations: [GeocodedLocation] = [] {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    private var geocodingRequest: Moya.Cancellable?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.estimatedRowHeight = 50
        tableView.rowHeight = UITableViewAutomaticDimension
        
        tableView.register(GeocodedLocationCell.self)
    }
    
}

extension SearchResultsViewController {
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return locations.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: GeocodedLocationCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
        let location = locations[indexPath.row]
        cell.configureForLocation(location)
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let location = locations[indexPath.row]
        delegate?.searchResultsViewController(self, didSelectLocation: location)
    }
    
}

extension SearchResultsViewController: UISearchResultsUpdating {
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        guard let searchTerm = searchController.searchBar.text where !searchTerm.isEmpty else {
            self.locations = []
            return
        }
        let logger = Evergreen.getLogger("Geocoding")
        
        geocodingRequest?.cancel()

        logger.debug("Requesting geocoded locations for search term \(searchTerm)...")
        geocodingRequest = openLocationService.request(.geocode(freeFormAddress: searchTerm, maxResponses: 20)) { result in
            switch result {
            
            case .Success(let response):
                do {
                    try response.filterSuccessfulStatusCodes()
                } catch {
                    logger.error("Invalid status code \(response.statusCode)", error: error)
                    return
                }
                do {
                    let locations = try response.mapGeocodedLocations()
                    logger.debug("Found \(locations.count) geocoded locations for search term \(searchTerm).")
                    logger.verbose(locations)
                    self.locations = locations
                } catch {
                    logger.error("Unable to parse response to geocoded locations.", error: error)
                    return
                }
                
            case .Failure(let error):
                print(error)
            }
            
        }
    }
    
}
