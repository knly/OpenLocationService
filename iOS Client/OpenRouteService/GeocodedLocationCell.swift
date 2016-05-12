//
//  GeocodedLocationCell.swift
//  ORS
//
//  Created by Nils Fischer on 12.05.16.
//  Copyright © 2016 Geographisches Institut der Universität Heidelberg, Abteilung Geoinformatik. All rights reserved.
//

import UIKit
import OpenLocationService


class GeocodedLocationCell: UITableViewCell, NibLoadable {

    @IBOutlet var addressLabel: UILabel!
    
    func configureForLocation(location: GeocodedLocation) {
        addressLabel.text = location.address.localizedDescription
    }
}
