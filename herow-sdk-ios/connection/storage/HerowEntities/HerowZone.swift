//
//  HerowZone.swift
//  herow-sdk-ios
//
//  Created by Damien on 25/01/2021.
//

import Foundation

public struct HerowZone: Zone {
    var zonehash: String
    var lat: Double
    var lng: Double
    var radius: Double
    var campaigns: [String]
    var access: Access?
    var liveEvent: Bool

    init( hash: String, lat: Double, lng: Double, radius: Double, campaigns: [String], access: Access?, liveEvent: Bool) {
     self.zonehash = hash
     self.lat = lat
     self.lng = lng
     self.radius = radius
     self.campaigns = campaigns
     self.access = access
     self.liveEvent = liveEvent
     }

    func getHash() -> String {
        return zonehash
    }

    func getLat() -> Double {
        return lat
    }

    func getLng() -> Double {
        return lng
    }

    func getRadius() -> Double {
        return radius
    }

    func getCampaigns() -> [String] {
        return campaigns
    }

    func getAccess() -> Access? {
        return access
    }

    func getLiveEvent() -> Bool {
        return liveEvent
    }

    

}

