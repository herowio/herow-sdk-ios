//
//  AbsoluteTimeProviderForTests.swift
//  ConnectPlaceCommon
//
//  Created by Ludovic Vimont on 04/09/2017.
//  Copyright © 2017 Connecthings. All rights reserved.
//

import Foundation

@objc public class TimeProviderAbsolute: NSObject, TimeProvider {
    override public init() {
        super.init()
    }

    public func getTime() -> Double {
        return Date().timeIntervalSince1970
    }
}
