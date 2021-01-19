//
//  PlaceLocation.swift
//  ConnectPlaceCommon
//
//  Created by Connecthings on 15/01/2018.
//  Copyright © 2018 Connecthings. All rights reserved.
//

import Foundation
import CoreLocation

public protocol PlaceLocation: Place, Codable {
    var location: CLLocation { get set }

    var radius: Double { get }

    var distance: Double? { get set }

    var distanceFromBorder: Double? { get set }

    func liveEventEnable() -> Bool

    func setliveEventEnable(_ enable: Bool)
}
