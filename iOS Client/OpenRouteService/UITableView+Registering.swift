//
//  UITableView+Registering.swift
//  card
//
//  Created by Nils Fischer on 26.03.16.
//  Copyright © 2016 viWiD Webdesign & iOS Development. All rights reserved.
//

import UIKit

protocol Reusable {
    
    static var reuseIdentifier: String { get }
    
}

extension Reusable where Self: UIView {
    
    static var reuseIdentifier: String {
        return NSStringFromClass(self).componentsSeparatedByString(".").last!
    }
    
}

extension UITableViewCell: Reusable {}
extension UITableViewHeaderFooterView: Reusable {}
extension UICollectionReusableView: Reusable {}


protocol NibLoadable {
    
    static var nibName: String { get }

}

extension NibLoadable where Self: UIView {
    
    static var nibName: String {
        return NSStringFromClass(self).componentsSeparatedByString(".").last!
    }
    
}

extension UITableView {
    
    func register<C: UITableViewCell where C: Reusable>(_: C.Type) {
        self.registerClass(C.self, forCellReuseIdentifier: C.reuseIdentifier)
    }
    
    func register<C: UITableViewCell where C: Reusable, C: NibLoadable>(_: C.Type) {
        let bundle = NSBundle(forClass: C.self)
        self.registerNib(UINib(nibName: C.nibName, bundle: bundle), forCellReuseIdentifier: C.reuseIdentifier)
    }

    func register<V: UITableViewHeaderFooterView where V: Reusable, V: NibLoadable>(_: V.Type) {
        let bundle = NSBundle(forClass: V.self)
        self.registerNib(UINib(nibName: V.nibName, bundle: bundle), forHeaderFooterViewReuseIdentifier: V.reuseIdentifier)
    }

    func dequeueReusableCell<C: UITableViewCell where C: Reusable>(forIndexPath indexPath: NSIndexPath) -> C {
        guard let cell = self.dequeueReusableCellWithIdentifier(C.reuseIdentifier, forIndexPath: indexPath) as? C else {
            fatalError("Unable to dequeue reusable cell with identifier \(C.reuseIdentifier).")
        }
        return cell
    }

    func dequeueReusableHeaderFooterView<V: UITableViewHeaderFooterView where V: Reusable>() -> V {
        guard let view = self.dequeueReusableHeaderFooterViewWithIdentifier(V.reuseIdentifier) as? V else {
            fatalError("Unable to dequeue reusable header footer view with identifier \(V.reuseIdentifier).")
        }
        return view
    }

}

extension UICollectionView {
    
    func register<C: UICollectionViewCell where C: Reusable>(_: C.Type) {
        self.registerClass(C.self, forCellWithReuseIdentifier: C.reuseIdentifier)
    }
    
    func register<C: UICollectionViewCell where C: Reusable, C: NibLoadable>(_: C.Type) {
        let bundle = NSBundle(forClass: C.self)
        self.registerNib(UINib(nibName: C.nibName, bundle: bundle), forCellWithReuseIdentifier: C.reuseIdentifier)
    }
    
    func registerReusableSupplementaryView<V: UICollectionReusableView where V: Reusable, V: NibLoadable>(_: V.Type, ofKind kind: String) {
        let bundle = NSBundle(forClass: V.self)
        self.registerNib(UINib(nibName: V.nibName, bundle: bundle), forSupplementaryViewOfKind: kind, withReuseIdentifier: V.reuseIdentifier)
    }

    func dequeueReusableCell<C: UICollectionViewCell where C: Reusable>(forIndexPath indexPath: NSIndexPath) -> C {
        guard let cell = self.dequeueReusableCellWithReuseIdentifier(C.reuseIdentifier, forIndexPath: indexPath) as? C else {
            fatalError("Unable to dequeue reusable cell with identifier \(C.reuseIdentifier).")
        }
        return cell
    }
    
    func dequeueReusableSupplementaryView<V: UICollectionReusableView where V: Reusable>(ofKind kind: String, forIndexPath indexPath: NSIndexPath) -> V {
        guard let view = self.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: V.reuseIdentifier, forIndexPath: indexPath) as? V else {
            fatalError("Unable to dequeue reusable header footer view with identifier \(V.reuseIdentifier).")
        }
        return view
    }
    
}
