//
//  NSDictionary+merge.swift
//  ConnectPlaceCommon
//
//  Created by Ludovic Vimont on 16/10/2017.
//  Copyright © 2017 Connecthings. All rights reserved.
//

import Foundation

public extension NSDictionary {
    // swiftlint:disable force_cast
    func merge(dict1: NSDictionary, dict2: NSDictionary) -> NSDictionary {
        let result = NSMutableDictionary.init(dictionary: dict1)

        dict2.enumerateKeysAndObjects({ (key, obj, _) in
            if dict1.object(forKey: key) != nil {
                if obj is NSDictionary {
                    if let objDictionary = dict1.object(forKey: key) as? NSDictionary {
                        let newVal = objDictionary.merge(objDictionary)
                        result.setObject(newVal, forKey: key as! NSCopying)
                    }
                } else {
                    result.setObject(obj, forKey: key as! NSCopying)
                }
            } else {
                result.setObject(obj, forKey: key as! NSCopying)
            }
        })

        return result.mutableCopy() as! NSDictionary
    }

    func merge(_ with: NSDictionary) -> NSDictionary {
        return self.merge(dict1: self, dict2: with)
    }
}
