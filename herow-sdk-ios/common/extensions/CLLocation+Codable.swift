//
//  CLLocation+codable.swift
//  ConnectPlaceGeoDetection
//
//  Created by Connecthings on 10/01/2018.
//  Copyright © 2018 Connecthings. All rights reserved.
//

import Foundation
import CoreLocation

public struct DecodableLocation: Codable {
    var latitude: CLLocationDegrees
    var longitude: CLLocationDegrees
    var altitude: CLLocationDistance = 0
    var horizontalAccuracy: CLLocationAccuracy = 0
    var verticalAccuracy: CLLocationAccuracy = 0
    var speed: CLLocationSpeed = 0
    var course: CLLocationDirection = 0
    var timestamp: Date = Date()
}

extension CLLocation: Encodable {
    enum CodingKeys: String, CodingKey {
        case latitude = "lat"
        case longitude = "lng"
        case altitude
        case horizontalAccuracy
        case speed
        case timestamp
    }

    public convenience init(model: DecodableLocation) {
        self.init(coordinate: CLLocationCoordinate2DMake(model.latitude, model.longitude),
                  altitude: model.altitude, horizontalAccuracy: model.horizontalAccuracy,
                  verticalAccuracy: model.verticalAccuracy, course: model.course,
                  speed: model.speed, timestamp: model.timestamp)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(coordinate.latitude, forKey: .latitude)
        try container.encode(coordinate.longitude, forKey: .longitude)
        try container.encode(altitude, forKey: .altitude)
        try container.encode(horizontalAccuracy, forKey: .horizontalAccuracy)
        try container.encode(speed, forKey: .speed)
        let timestampMs = timestamp.timeIntervalSince1970 * 1000
        try container.encode(timestampMs, forKey: .timestamp)
    }
}
