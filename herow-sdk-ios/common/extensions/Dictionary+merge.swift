//
//  Dictionary+merge.swift
//  ConnectPlaceCommon
//
//  Created by Ludovic Vimont on 16/10/2017.
//  Copyright © 2017 Connecthings. All rights reserved.
//

import Foundation
import UIKit

private protocol Mergable {
    func mergeWithSame<T>(right: T) -> T?
}

public extension Dictionary {
    // swiftlint:disable identifier_name

    /**
     Merge Dictionaries
     - Parameter right:  Source dictionary with values to be merged with current dictionary
     - Returns: Merged dictionay
     */
    func merge(right: Dictionary) -> Dictionary {
        var merged = self
        for (k, rv) in right {
            // case of existing left value
            if let lv = self[k] {
                if let lv = lv as? Mergable, type(of: lv) == type(of: rv) {
                    let m = lv.mergeWithSame(right: rv)
                    merged[k] = m
                } else if lv is Mergable {
                    assert(false, "Expected common type for matching keys!")
                } else if !(lv is Mergable), let _ = lv as? NSArray {
                    assert(false, "Dictionary literals use incompatible Foundation Types")
                } else if !(lv is Mergable), let _ = lv as? NSDictionary {
                    assert(false, "Dictionary literals use incompatible Foundation Types")
                } else {
                    merged[k] = rv
                }
            } else {
                merged[k] = rv
            }
        }
        return merged
    }
}

extension Array: Mergable {
    func mergeWithSame<T>(right: T) -> T? {
        if let right = right as? Array {
            return (self + right) as? T
        }
        assert(false)
        return nil
    }
}

extension Dictionary: Mergable {
    func mergeWithSame<T>(right: T) -> T? {
        if let right = right as? Dictionary {
            return self.merge(right: right) as? T
        }
        assert(false)
        return nil
    }
}

extension Set: Mergable {
    func mergeWithSame<T>(right: T) -> T? {
        if let right = right as? Set {
            return self.union(right) as? T
        }
        assert(false)
        return nil
    }
}
