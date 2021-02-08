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
    let latitude: CLLocationDegrees
    let longitude: CLLocationDegrees
    let altitude: CLLocationDistance = 0
    let horizontalAccuracy: CLLocationAccuracy = 0
    let verticalAccuracy: CLLocationAccuracy = 0
    let speed: CLLocationSpeed = 0
    let course: CLLocationDirection = 0
    let timestamp: Date = Date()
}

extension CLLocation: Encodable {
    enum CodingKeys: String, CodingKey {
        case latitude = "lat"
        case longitude = "lng"
        case altitude
        case horizontalAccuracy
       // case verticalAccuracy
        case speed
        //case course
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
       // try container.encode(verticalAccuracy, forKey: .verticalAccuracy)
        try container.encode(speed, forKey: .speed)
       // try container.encode(course, forKey: .course)
        let timestampMs = timestamp.timeIntervalSince1970 * 1000
        try container.encode(timestampMs, forKey: .timestamp)
    }
}
