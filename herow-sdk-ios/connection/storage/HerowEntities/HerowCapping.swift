//
//  HerowCapping.swift
//  herow_sdk_ios
//
//  Created by Damien on 27/04/2021.
//

import Foundation
@objc public class HerowCapping: NSObject, Capping {


    var campaignId: String
    var razDate: Date
    var count: Int64 = 0
    public func getId() -> String {
        return campaignId
    }

    public func getRazDate() -> Date {
        return razDate
    }

    public func getCount() -> Int64 {
        return count
    }

    public func setRazDate(date: Date) {
        self.razDate = date
    }

    public func setCount(count: Int64) {
        self.count = count
    }

    public required init(id: String, razDate: Date, count: Int64) {
        self.campaignId = id
        self.razDate = razDate
        self.count = count
    }


}
