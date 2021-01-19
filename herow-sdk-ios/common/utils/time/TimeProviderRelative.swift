//
//  TimeRelativeGenerator.swift
//  ConnectPlaceCommon
//
//  Created by Connecthings on 10/07/2017.
//  Copyright © 2017 Connecthings. All rights reserved.
//

import Foundation

@objc public class TimeProviderRelative: NSObject, TimeProvider {
    override public init() {
        super.init()
    }

    public func getTime() -> Double {
        return ProcessInfo.processInfo.systemUptime
    }
}
