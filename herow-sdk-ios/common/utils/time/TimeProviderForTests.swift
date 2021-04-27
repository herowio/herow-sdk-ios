//
//  ProviderTimeForTests.swift
//  ConnectPlaceProviderTests
//
//  Created by Connecthings on 10/07/2017.
//  Copyright © 2017 Connecthings. All rights reserved.
//

import Foundation

public class TimeProviderForTests: TimeProvider {
    var date: Date

    public init() {
        date = Date()
    }

    public func getTime() -> Double {
        return date.timeIntervalSince1970
    }

    public func updateNow() {
        date = Date()
    }

    public func addingTimeInterval(timeInterval: TimeInterval) {
        date = date.addingTimeInterval(timeInterval)
    }

    public func setHour(hour: Int, minutes: Int) {
        date = date.setTime(hour: hour, min: minutes) ?? date
    }


}
