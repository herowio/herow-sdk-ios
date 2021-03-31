//
//  APIZone.swift
//  herow-sdk-ios
//
//  Created by Damien on 25/01/2021.
//

import Foundation

struct APIZone: Codable, Zone {

    var hash: String
    var lat: Double
    var lng: Double
    var radius: Double
    var campaigns: [String]
    var access: APIAccess?
    var liveEvent: Bool

    init( hash: String, lat: Double, lng: Double, radius: Double, campaigns: [String], access: Access?, liveEvent: Bool) {
     self.hash = hash
     self.lat = lat
     self.lng = lng
     self.radius = radius
     self.campaigns = campaigns
     self.access = access as? APIAccess
     self.liveEvent = liveEvent
     }

    func getHash() -> String {
        return hash
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

    static public func decode(data: Data) -> Zone? {
        let decoder = JSONDecoder()
        guard let zone = try? decoder.decode(Self.self, from: data) else {
            return nil
        }
        return zone
    }


}

extension Encodable {
    public func encode() -> Data? {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(self) else {
            return nil
        }
        GlobalLogger.shared.debug("Encode: \(String(decoding: data, as: UTF8.self))")
        return data
    }

    public func encodeAsArray() -> Data? {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode([self]) else {
            return nil
        }
        return data
    }
}


