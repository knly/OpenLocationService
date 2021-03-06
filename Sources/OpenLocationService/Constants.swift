//
//  Constants.swift
//  ORS
//
//  Created by Nils Fischer on 11.05.16.
//  Copyright © 2016 Geographisches Institut der Universität Heidelberg, Abteilung Geoinformatik. All rights reserved.
//

import Foundation
import UIKit


enum Constants {
    
    static let ORSTilesURLTemplate = "http://korona.geog.uni-heidelberg.de/tiles/uni-hd/x={x}&y={y}&z={z}"
    
    enum UserDefaultsKey {
        static let preferredTransportationMode = "OLSUserDefaultsKeyPreferredTransportationMode"
    }

}


// MARK: Colors

extension UIColor {
    
    public class func ols_brandColor() -> UIColor {
        return UIColor(red: 255/255, green: 107/255, blue: 54/255, alpha: 1)
    }
    
}


// MARK: User Defaults

public var userDefaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
