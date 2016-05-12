//
//  RouteButton.swift
//  uni-hd
//
//  Created by Nils Fischer on 21.04.16.
//  Copyright © 2016 Universität Heidelberg. All rights reserved.
//

import UIKit
import CoreLocation
import PromiseKit


class RouteButton: UIControl {

    private lazy var transportSymbol: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .Center
        return imageView
    }()
    private lazy var routeDetailLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption2)
        return label
    }()
    
    private var _transportationMode: TransportationMode?
    var transportationMode: TransportationMode {
        if let transportationMode = _transportationMode {
            return transportationMode
        } else {
            let transportationMode = userDefaults.preferredTransportationMode ?? .bicycle
            _transportationMode = transportationMode
            return transportationMode
        }
    }
    let location: Location
    
    init(location: Location) {
        self.location = location
        let bottomMargin: CGFloat = 50
        let margin: CGFloat = 5
        super.init(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 44, height: 50 + bottomMargin)))
        // layout
        transportSymbol.translatesAutoresizingMaskIntoConstraints = false
        routeDetailLabel.translatesAutoresizingMaskIntoConstraints = false
        let stackView = UIStackView(arrangedSubviews: [ transportSymbol, routeDetailLabel])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .Vertical
        stackView.alignment = .Center
        stackView.distribution = .Fill
        stackView.spacing = 2
        addSubview(stackView)
        addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-(>=\(margin))-[stackView]-(>=\(margin))-|", options: .DirectionLeadingToTrailing, metrics: nil, views: [ "stackView": stackView ]))
        addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-(>=\(margin))-[stackView]-(>=\(margin + bottomMargin))-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: [ "stackView": stackView ]))
        addConstraint(NSLayoutConstraint(item: stackView, attribute: .CenterX, relatedBy: .Equal, toItem: self, attribute: .CenterX, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: stackView, attribute: .CenterY, relatedBy: .Equal, toItem: self, attribute: .CenterY, multiplier: 1, constant: -bottomMargin / 2))
        configure()
        // add actions
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(RouteButton.tap(_:)))
        addGestureRecognizer(tapGestureRecognizer)
        // subscribe to changes
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(RouteButton.userDefaultsChanged(_:)), name: NSUserDefaultsDidChangeNotification, object: userDefaults)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configure() {
        // transportation symbol
        transportSymbol.image = UIImage(named: {
            switch self.transportationMode {
            case .pedestrian: return "transport_pedestrian"
            case .bicycle: return "transport_bicycle"
            case .wheelchair: return "transport_wheelchair"
            case .car: return "transport_car"
            }
        }(), inBundle: NSBundle(forClass: RouteButton.self), compatibleWithTraitCollection: nil)
        // try to find route details and display
        routeDetailLabel.hidden = true
        Route.request(from: UserLocation(), to: self.location, options: Route.Options(transportationMode: self.transportationMode)).then { route -> Void in
            if let duration = route.duration {
                let durationFormatter = NSDateComponentsFormatter()
                durationFormatter.allowedUnits = NSCalendarUnit.Minute.union(.Hour)
                durationFormatter.unitsStyle = .Abbreviated
                self.routeDetailLabel.text = durationFormatter.stringFromTimeInterval(duration)
                self.routeDetailLabel.hidden = false
            }
        }
    }
    
    override func tintColorDidChange() {
        super.tintColorDidChange()
        backgroundColor = tintColor
        transportSymbol.tintColor = UIColor.whiteColor()
        routeDetailLabel.textColor = UIColor.whiteColor()
    }
    
    @objc func userDefaultsChanged(notification: NSNotification) {
        if let preferredTransportationMode = userDefaults.preferredTransportationMode where transportationMode != preferredTransportationMode {
            _transportationMode = nil
            configure()
        }
    }

    
    // MARK: - User Interaction
    
    @objc func tap(gestureRecognizer: UITapGestureRecognizer) {
        sendActionsForControlEvents(UIControlEvents.TouchUpInside)
    }
    
    
}
