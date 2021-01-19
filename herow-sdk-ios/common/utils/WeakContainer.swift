//
//  WeakContainer.swift
//  herow-sdk-ios
//
//  Created by Damien on 15/01/2021.
//

public class WeakContainer<T>{
    weak var internalValue : AnyObject?
    public  init (value: T) {
        internalValue = value as AnyObject
    }
    func get() -> T? {
        return internalValue as? T
    }
}
