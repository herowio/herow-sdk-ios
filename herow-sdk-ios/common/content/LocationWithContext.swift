//
//  LocationWithCotnext.swift
//  ConnectPlaceCommon
//
//  Created by Connecthings on 09/01/2018.
//  Copyright © 2018 Connecthings. All rights reserved.
//

import Foundation
import CoreLocation

public struct NearByPoi: Codable {
    var id: String
    var distance: Double
    var tags: [String]

   public  init(id: String, distance: Double, tags:[String]) {
        self.id = id
        self.distance = distance
        self.tags = tags
    }

    public func getDistance() -> Double {
        return distance
    }
}

public class LocationWithContext: Codable {
    public private(set) var lat: Double
    public private(set) var lng: Double
    public let horizontalAccuracy: Double
    public let alt: Double
    public let verticalAccuracy: Double
    public let speed: Double
    public let speedAccuracy: Double
    public let bearing: Double
    public let bearingAccuracy: Double
    public let timestamp: Date
    public let provider: String
    public var pois: [NearByPoi]?

    public init(_ location: CLLocation) {
        lat = location.coordinate.latitude
        lng = location.coordinate.longitude
        horizontalAccuracy = location.horizontalAccuracy
        alt = location.altitude
        verticalAccuracy = location.verticalAccuracy
        speed = location.speed
        speedAccuracy = -1
        bearing = location.course
        bearingAccuracy = -1
        timestamp = location.timestamp
        provider = "unknown"
        checkRange()
    }

    public init(lat: Double, lng: Double, timestamp: Date = Date()) {
        self.lat = lat
        self.lng = lng
        self.timestamp = timestamp
        horizontalAccuracy = -1
        alt = -1
        verticalAccuracy = -1
        speed = -1
        speedAccuracy = -1
        bearing = -1
        bearingAccuracy = -1
        provider = "NONE"
        checkRange()
    }

    func checkRange() {
        lat = checkRange(value: lat, range: 90)
        lng = checkRange(value: lng, range: 180)
    }

    func checkRange(value: Double, range: Double) -> Double {
        let min = -range
        let max = range
        if value >= min && value <= max {
            return value
        }
        let nbOccurance = round(value / range)
        let base: Double = range * nbOccurance
        let multiplicateur: Double = value < 0 ? 1 : -1
        return range * multiplicateur + value - base
    }
}

extension LocationWithContext {
    enum CodingKeys: String, CodingKey {

        case lat = "lat"
        case lng = "lng"
        case horizontalAccuracy = "horizontalAccuracy"
        case alt = "alt"
        case verticalAccuracy = "verticalAccuracy"
        case speed = "speed"
        case speedAccuracy = "speedAccuracy"
        case bearing = "bearing"
        case bearingAccuracy = "bearingAccuracy"
        case timestamp = "timestamp"
        case provider = "provider"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(lat, forKey: .lat)
        try container.encode(lng, forKey: .lng)
        try container.encode(horizontalAccuracy, forKey: .horizontalAccuracy)
        try container.encode(verticalAccuracy, forKey: .verticalAccuracy)
        try container.encode(speed, forKey: .speed)
        try container.encode(speedAccuracy, forKey: .speedAccuracy)
        try container.encode(bearing, forKey: .bearing)
        try container.encode(bearingAccuracy, forKey: .bearingAccuracy)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(provider, forKey: .provider)

    }
}
