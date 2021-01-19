//
//  CodableCoordinates.swift
//  ConnectPlaceCommon
//
//  Created by Amine on 31/08/2018.
//  Copyright © 2018 Connecthings. All rights reserved.
//

import Foundation
import CoreLocation

public class CodableCoordinates: Codable {
    public let lat: Double
    public let lng: Double

    public init(_ coordinates: CLLocationCoordinate2D) {
        lat = coordinates.latitude
        lng = coordinates.longitude
    }

    public init(lat: Double, lng: Double) {
        self.lat = lat
        self.lng = lng
    }
}
