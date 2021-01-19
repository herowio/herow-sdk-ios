//
//  AtomicBoolean.swift
//  ConnectPlaceCommon
//
//  Created by Ludovic Vimont on 02/09/2019.
//  Copyright © 2019 Connecthings. All rights reserved.
//

import Foundation
import Dispatch

// swiftlint:disable identifier_name
let q = DispatchQueue(label: "com.connecthings.atomic.boolean")

public struct AtomicBoolean {
    private var semaphore = DispatchSemaphore(value: 1)
    private var b: Bool = false
    public var val: Bool {
        get {
            semaphore.wait()
            let tmp = b
            semaphore.signal()
            return tmp
        }
        set {
            semaphore.wait()
            b = newValue
            semaphore.signal()
        }
    }
}
