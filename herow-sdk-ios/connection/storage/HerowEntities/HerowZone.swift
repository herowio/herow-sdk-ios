//
//  HerowZone.swift
//  herow-sdk-ios
//
//  Created by Damien on 25/01/2021.
//

import Foundation

@objc public class HerowZone: NSObject, Zone {
    var zonehash: String
    var lat: Double
    var lng: Double
    var radius: Double
    var campaigns: [String]
    var access: Access?


    convenience init( zone: Zone) {
        self.init(hash: zone.getHash(), lat: zone.getLat(), lng: zone.getLng(), radius: zone.getRadius(), campaigns: zone.getCampaigns(), access: zone.getAccess())
    }
    required init( hash: String, lat: Double, lng: Double, radius: Double, campaigns: [String], access: Access?) {
     self.zonehash = hash
     self.lat = lat
     self.lng = lng
     self.radius = radius
     self.campaigns = campaigns
     self.access = access
     }

    public func getHash() -> String {
        return zonehash
    }

    public func getLat() -> Double {
        return lat
    }

    public func getLng() -> Double {
        return lng
    }

    public  func getRadius() -> Double {
        return radius
    }

    public func getCampaigns() -> [String] {
        return campaigns
    }

    public func getAccess() -> Access? {
        return access
    }

}

