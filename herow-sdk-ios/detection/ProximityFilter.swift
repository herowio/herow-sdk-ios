//
//  ProximityFilter.swift
//  herow_sdk_ios
//
//  Created by Damien on 23/09/2021.
//

import Foundation
import CoreLocation


// swiftlint:disable identifier_name
@objc public protocol ProximityFilterProtocol: AnyObject {
    func currentTime() -> Date
    func setCurrentTime(_ date: Date)
    func processState(currentLocation: CLLocation) -> ProximityResult?
}

@objc public class ProximityResult: NSObject {
    private var confidence: Double = 0
    private var distance: Double = 0
    private var lastRefuseLocation: CLLocation?
    private var location: CLLocation?
    private var fromOldLocation: Bool = false

    public func getConfidence() -> Double {
        return confidence
    }

    public func getDistance() -> Double {
        return distance
    }

    public func getlastRefuseLocation() -> CLLocation? {
        return lastRefuseLocation
    }
    public func getLocation() -> CLLocation? {
        return location
    }

    public func getFromOldLocation() -> Bool {
        return fromOldLocation
    }

    public init(_ confidence: Double, _ distance: Double, _ location: CLLocation?, _ lastBadPosition: CLLocation?, _ fromOld: Bool) {
        self.confidence = confidence
        self.distance = distance
        self.location = location
        self.lastRefuseLocation = lastBadPosition
        self.fromOldLocation = fromOld
    }
}
@objc class ProximityFilter: NSObject, ProximityFilterProtocol {

    public func currentTime() -> Date {
        return timeProvider.getDate()
    }

    func setCurrentTime(_ date: Date) {

    }

    static let defaultSpeed: Double = 2
    static let minimumDistanceAllowed: Double = 30
    static let minimumAccuracyAllowed: Double = 50
    static let invalidationFilterThresholdAfterReuseAccuracy: Double = 65
    private var previousLocation: CLLocation?
    private var previousTimeInterval: Double = 0
    private var previousValidDate = Date()
    static let  validityDistanceFactor: Double = 1.5
    private var previousSpeed: Double = ProximityFilter.defaultSpeed
    private var invalidationFilterTresholdConfidence: Double
    private var lastRefuseDate: Date?
    private var lastRefuseLocation: CLLocation?
    private var lastRefuseSpeed: Double = ProximityFilter.defaultSpeed
    private var firstTry = true
    private var timeProvider: TimeProvider
    public init(initialLocation: CLLocation, invalidationFilterTresholdConfidence: Double, timeProvider: TimeProvider = TimeProviderAbsolute()) {

        self.invalidationFilterTresholdConfidence = invalidationFilterTresholdConfidence
        self.timeProvider = timeProvider
        super.init()

        previousLocation = initialLocation
        previousValidDate = self.currentTime()
    }

    public func processState(currentLocation: CLLocation) -> ProximityResult? {
        let now = currentTime()
        var distance: Double = 0
        var physicalDistance: Double = 0
        var confidence: Double = 1
        var tmPreviousSpeed: Double?
        if let previous = previousLocation {
            let timeInterval = now.timeIntervalSince(previousValidDate)
            if timeInterval > 0 {
                GlobalLogger.shared.debug("ProximityFilter - computed speed : \(previousSpeed)")
                GlobalLogger.shared.debug("ProximityFilter - computed timeInterval : \(timeInterval)")
                distance = max(ProximityFilter.minimumDistanceAllowed, previousSpeed * timeInterval) * ProximityFilter.validityDistanceFactor
            } else {
                let tempFirstTry = firstTry
                firstTry = false
                return  ProximityResult(tempFirstTry ? 1 : 0, ProximityFilter.minimumDistanceAllowed, previous, lastRefuseLocation, false) // or nil ?
            }
            GlobalLogger.shared.debug("ProximityFilter - computed validation distance: \(distance)")
            physicalDistance = currentLocation.distance(from: previous)
            tmPreviousSpeed = physicalDistance / timeInterval
            if physicalDistance <= distance || ProximityFilter.minimumAccuracyAllowed >= currentLocation.horizontalAccuracy {
                confidence = 1
            } else {
                confidence = computeConfidence(currentLocation: currentLocation, previousLocation: previous, estimateDistance: distance)
            }
        } else {
            confidence = 1
            GlobalLogger.shared.debug("ProximityFilter - no previous location")
        }
        var confidenceFromRefuse = 0.0
        if (currentLocation.horizontalAccuracy <= (lastRefuseLocation?.horizontalAccuracy ?? ProximityFilter.invalidationFilterThresholdAfterReuseAccuracy)) {
           confidenceFromRefuse = computeWithLastRefuse(currentLocation)
        }

        let result = max(confidence, confidenceFromRefuse)
        let fromOldRefuse = confidenceFromRefuse > confidence
        let proximityResult = ProximityResult(result, distance, previousLocation, lastRefuseLocation, fromOldRefuse)
        //update values
        if result > invalidationFilterTresholdConfidence {
            if let speed = tmPreviousSpeed {
                previousSpeed = speed
            }
            previousValidDate = now
            previousLocation = currentLocation
            lastRefuseSpeed =  ProximityFilter.defaultSpeed
            lastRefuseDate = nil
            lastRefuseLocation = nil
            GlobalLogger.shared.debug("ProximityFilter - update location \(currentLocation) IS valid: confidence = \(result) distance: \(distance) m")
        } else {
            if let speed = tmPreviousSpeed {
                lastRefuseSpeed = speed
            }
            lastRefuseDate = now
            lastRefuseLocation = currentLocation
             GlobalLogger.shared.debug("ProximityFilter - update location \(currentLocation) IS NOT valid: confidence = \(result) distance: \(distance) m")
        }
        return proximityResult
    }

    private func computeWithLastRefuse(_ currentLocation: CLLocation) -> Double {
        var confidence: Double = 0
        var distance: Double  = 0
        let now = currentTime()

        if let previous = self.lastRefuseLocation, let lastDate =  self.lastRefuseDate {
            let  lastRefuseTimeInterval = now.timeIntervalSince(lastDate)
            if lastRefuseTimeInterval > 0 {
                distance = max(ProximityFilter.minimumDistanceAllowed, lastRefuseSpeed * lastRefuseTimeInterval)
                GlobalLogger.shared.debug("ProximityFilter - computed  from bad old location validation distance: \(distance)")
                if currentLocation.horizontalAccuracy <= previous.horizontalAccuracy {
                    // on ne traite que si le relevé à estimer à une meilleure accuracy que le dernier relevé refusé
                    confidence = computeConfidence(currentLocation: currentLocation, previousLocation: previous, estimateDistance: distance)
                }
            }
        }
        return confidence
    }

    private  func computeConfidence(currentLocation: CLLocation, previousLocation: CLLocation?, estimateDistance: Double) -> Double {
        var confidence: Double = 0
        guard let previousLocation = previousLocation else {
            return 1
        }
        let d: Double = currentLocation.distance(from: previousLocation)
        if d <= ProximityFilter.minimumDistanceAllowed || estimateDistance == 0 {
            return 1
        }
        let currentRadius: Double = currentLocation.horizontalAccuracy
        let speedRadius: Double =  estimateDistance
        GlobalLogger.shared.debug("ProximityFilter - confidence parameters : currentRadius = \(currentRadius) speedRadius = \(speedRadius) distance = \(d)")
        var intersectArea: Double  = 0
        let r1: Double = max(currentRadius, speedRadius)
        let r2: Double = min(currentRadius, speedRadius)
        let r1r1 = r1 * r1
        let r2r2 = r2 * r2
        let dd: Double = d * d
        if r1 + r2  <= d {
            intersectArea = 0
        } else {
            if r1 - r2 >= d {
                intersectArea = Double.pi * r2r2
            } else {
                let d1 = ((r1r1 - r2r2) + dd) / (2 * d)
                let d2 = ((r2r2 - r1r1) + dd) / (2 * d)
                let a1 = r1r1 * acos(d1 / r1) - d1 * sqrt(r1r1 - d1 * d1)
                let a2 = r2r2 * acos(d2 / r2) - d2 * sqrt(r2r2 - d2 * d2)
                intersectArea = a1 + a2
            }
        }
        GlobalLogger.shared.debug("ProximityFilter - computed intersect Area : \(intersectArea)")
        confidence = min(1, intersectArea / (Double.pi * currentRadius * currentRadius))
        GlobalLogger.shared.debug("ProximityFilter - computed confidence : \(confidence)")
        return confidence
    }
}
