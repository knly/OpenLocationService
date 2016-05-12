//
//  ResourceBundle.swift
//  Pods
//
//  Created by Nils Fischer on 13.05.16.
//
//

import Foundation

public let bundle = NSBundle(forClass: OLSMapViewController.self)
public let resourceBundle = NSBundle(URL: bundle.URLForResource("OpenLocationService", withExtension: "bundle")!)!
