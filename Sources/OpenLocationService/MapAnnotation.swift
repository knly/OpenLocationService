//
//  MapAnnotation.swift
//  Pods
//
//  Created by Nils Fischer on 12.05.16.
//
//

import Foundation

protocol MapAnnotation: Location {
    
    var title: String? { get }
    var subtitle: String? { get }
    
}
