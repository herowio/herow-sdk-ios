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

    private enum CodingKeys: String, CodingKey {
        case zonehash
        case lat
        case lng
        case radius
        case campaigns
        case access
    }

    required public init(from decoder:Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            zonehash = try values.decode(String.self, forKey: .zonehash)
            lat = try values.decode(Double.self, forKey: .lat)
            lng = try values.decode(Double.self, forKey: .lat)
            radius = try values.decode(Double.self, forKey: .radius)
            campaigns = try values.decode([String].self, forKey: .campaigns)
            access = try values.decode(HerowAccess.self, forKey: .access)
        }

    public func encode(to encoder: Encoder) throws {
          var container = encoder.container(keyedBy: CodingKeys.self)
          try container.encode(zonehash, forKey: .zonehash)
          try container.encode(lat, forKey: .lat)
          try container.encode(lng, forKey: .lng)
          try container.encode(radius, forKey: .radius)
          try container.encode(campaigns, forKey: .campaigns)
         if let myAccess = access as? HerowAccess {
          try container.encode(myAccess as HerowAccess, forKey: .access)
        }
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

