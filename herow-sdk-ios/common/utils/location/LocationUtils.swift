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

    public static func computeConfidence( centerLocation: CLLocation, location: CLLocation, radius: Double) -> Double {
        var result: Double = 0
        let center = CLLocation(latitude: centerLocation.coordinate.latitude, longitude: centerLocation.coordinate.longitude)
        let d = center.distance(from: location) as Double
        let zoneRadius = radius
        let accuracyRadius = location.horizontalAccuracy
        var intersectArea: Double  = 0
        let r1 = max(zoneRadius, accuracyRadius)
        let r2 = min(zoneRadius, accuracyRadius)
        let r1r1 = r1 * r1
        let r2r2 = r2 * r2
        let dd = d * d
        if r1 + r2  <= d {
            intersectArea = 0
        } else {
            if r1 - r2 >= d {
                GlobalLogger.shared.debug("full inclusion: distance = \(d)")
                intersectArea = Double.pi * r2r2
            } else {
                let d1 = ((r1r1 - r2r2) + dd) / (2 * d)
                let d2 = ((r2r2 - r1r1) + dd) / (2 * d)
                let cos1 = max(min(d1 / r1, 1), -1)
                let cos2 = max(min(d2 / r2, 1), -1)
                let a1 = r1r1 * acos(cos1) - d1 * sqrt(abs(r1r1 - d1 * d1))
                let a2 = r2r2 * acos(cos2) - d2 * sqrt(abs(r2r2 - d2 * d2))
                intersectArea = abs(a1 + a2)
            }
        }
        result = min(1, intersectArea / (Double.pi * accuracyRadius * accuracyRadius)).round(to: 2)
       
        return result
    }











}
