//
//  LocationUtils.swift
//  herow-sdk-ios
//
//  Created by Damien on 27/01/2021.
//

import Foundation
import CoreLocation

public class LocationUtils {
    static let regionIdPrefix: String = "com.connecthings.connectplace.geofence.region"
    static let polarRadiusAverage: Double = 6356752
    static let equatorialRadiusAverage: Double = 6378137
    static let degreesToRadians: Double = .pi / 180
    static let radiansToDegrees: Double = 1.0 / LocationUtils.degreesToRadians

    static func isGeofenceRegion(_ region: CLRegion) -> Bool {
        return region.isKind(of: CLCircularRegion.self)
    }

    static func degreesToRadians(_ degrees: Double) -> Double {
        if #available(iOS 10.0, *) {
            return Measurement(value: degrees, unit: UnitAngle.degrees).converted(to: .radians).value
        } else {
             return degrees * self.degreesToRadians
        }
    }

    static func radiansToDegrees(_ radians: Double) -> Double {
        if #available(iOS 10.0, *) {
            return Measurement(value: radians, unit: UnitAngle.radians).converted(to: .degrees).value
        } else {
            return radians * self.radiansToDegrees
        }
    }

    static func location2(location: CLLocation,
                          byMovingDistance distance: Double,
                          withBearing bearing: Double) -> CLLocation {

        let bearingRadian = degreesToRadians(bearing)
        // Radius for the horizontal degrees.
        let radiusXDegrees: Double = distanceToDegrees(distance: distance,
                                                       radius: equatorialRadiusAverage *
                                                        cos(degreesToRadians(location.coordinate.latitude)))
        // Radius for the vertical degrees.
        let radiusYDegrees: Double = distanceToDegrees(distance: distance, radius: polarRadiusAverage)

        let latitude = radiusXDegrees * cos(bearingRadian) + location.coordinate.latitude
        let longitude = radiusYDegrees * sin(bearingRadian) + location.coordinate.longitude

        return CLLocation(latitude: latitude, longitude: longitude)
    }

    static func distanceToDegrees(distance: Double, radius: Double) -> Double {
        return radiansToDegrees(distance / radius)
    }

    static func degreesToDistance(degrees: Double, radius: Double) -> Double {
        return degreesToRadians(degrees * radius)
    }

    public static func location(location: CLLocation,
                                byMovingDistance distance: Double,
                                withBearing bearing: Double) -> CLLocation {
        let distRadians = distance / (6372797.6) // earth radius in meters
        let bearingRadians: Double = LocationUtils.degreesToRadians(bearing)
        let lat1 = LocationUtils.degreesToRadians(location.coordinate.latitude)
        let lon1 = LocationUtils.degreesToRadians(location.coordinate.longitude)

        let lat2 = asin(sin(lat1) * cos(distRadians) + cos(lat1) * sin(distRadians) * cos(bearingRadians))
        let lon2 = lon1 + atan2(sin(bearingRadians) * sin(distRadians) * cos(lat1),
                                cos(distRadians) - sin(lat1) * sin(lat2))

        return CLLocation(latitude: LocationUtils.radiansToDegrees(lat2),
                          longitude: LocationUtils.radiansToDegrees(lon2))
    }



    static func randomLocation() -> CLLocation {

        let randomLat = Double.random(in: -90...90)
        let randomLong = Double.random(in: -180...180)
        let accuracy = 20.0
        let coor = CLLocationCoordinate2D(latitude: randomLat, longitude: randomLong)
        return CLLocation(coordinate: coor, altitude: 0, horizontalAccuracy: accuracy, verticalAccuracy: accuracy, timestamp: Date())
    }

    static func randomNearLocationBadAccuracy() -> CLLocation {

        let randomLat = 49.3355
        let randomLong = 3.9086
        let accuracy = 5000.0
        let coor = CLLocationCoordinate2D(latitude: randomLat, longitude: randomLong)
        return CLLocation(coordinate: coor, altitude: 0, horizontalAccuracy: accuracy, verticalAccuracy: accuracy, timestamp: Date())
    }

    static func randomSylvain() -> CLLocation {
       // <wpt lat="48.709583" lon="2.387505">
        let randomLat = 48.709583
        let randomLong = 2.387505
        let accuracy = 50.0
        let coor = CLLocationCoordinate2D(latitude: randomLat, longitude: randomLong)
        return CLLocation(coordinate: coor, altitude: 0, horizontalAccuracy: accuracy, verticalAccuracy: accuracy, timestamp: Date())
    }


}
