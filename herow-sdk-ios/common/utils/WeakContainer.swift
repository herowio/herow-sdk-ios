//
//  WeakContainer.swift
//  herow-sdk-ios
//
//  Created by Damien on 15/01/2021.
//

public class WeakContainer<T>: Equatable{
    weak var internalValue : AnyObject?
    public  init (value: T) {
        internalValue = value as AnyObject
    }
    public func get() -> T? {
        return internalValue as? T
    }
    public static func == (lhs: WeakContainer, rhs: WeakContainer) -> Bool {
        return lhs.internalValue === rhs.internalValue
    }
}
