//
//  LocationValidator.swift
//  herow_sdk_ios
//
//  Created by Damien on 23/09/2021.
//

import Foundation
import CoreLocation
public enum  ResultType: String {
    case invalid
    case valid
}

@objc public protocol  LocationValidatorProtocol: AnyObject {
     func initProximityFilter(initialLocation: CLLocation, invalidationFilterTresholdConfidence: Double) -> ProximityFilterProtocol
}

@objc public protocol  LocationValidatorDelegate: AnyObject {
    func didRunEstimation(_ result: FilterResult?)
}

@objc public class LocationValidator: NSObject, AppStateDelegate {

    private var lastLocation: CLLocation?
    private var lastGoodLocation: CLLocation?
    private var lastCovarianceValue: Double?
    private var lastComputedSpeed: Double = 5
    private var isInFG = true
    private var proximityFilter: ProximityFilterProtocol?
    private var failCount = 0
    static var delegates: [LocationValidatorDelegate] = [LocationValidatorDelegate]()
    public var invalidationFilterTresholdConfidence: Double = 0.2


    public func getProximityFilter() -> ProximityFilterProtocol? {
        return proximityFilter
    }
    // MARK: treatment
   public static func registerDelegate(_ delegate: LocationValidatorDelegate) {
        if !delegates.contains(where: { $0 === delegate }) {
            LocationValidator.delegates.append(delegate)
        }
    }

   public static func unRegisterDelegate(_ delegate: LocationValidatorDelegate) {
        if delegates.contains(where: { $0 === delegate }) {
            LocationValidator.delegates.removeAll(where: { $0 === delegate })
        }
    }

    public func runValidation(_ location: CLLocation) -> Bool {
        let resultType =  runEstimation(location)?.type
        return resultType == .valid
    }

    public func runEstimation(_ location: CLLocation) -> FilterResult? {
            return runConfidenceEstimation(location)
    }

    func initProximityFilter(initialLocation: CLLocation, invalidationFilterTresholdConfidence: Double) -> ProximityFilterProtocol {
        return ProximityFilter(initialLocation: initialLocation, invalidationFilterTresholdConfidence: invalidationFilterTresholdConfidence)
    }

    public func runConfidenceEstimation(_ location: CLLocation) -> FilterResult? {
        if proximityFilter == nil {
            proximityFilter  = initProximityFilter(initialLocation: location, invalidationFilterTresholdConfidence: invalidationFilterTresholdConfidence)
        }
        var result: FilterResult?
        let previous = proximityFilter?.getLastLocation()
        let proximityProccessingResult = proximityFilter?.processState(currentLocation: location)
        let confidence = proximityProccessingResult?.getConfidence()
        let speedradius = proximityProccessingResult?.getDistance()

        let previousBad = proximityProccessingResult?.getlastRefuseLocation()
        let fromLastRefuse = proximityProccessingResult?.getFromOldLocation() ?? false
        if let c = confidence, let d = speedradius {
            if c >= invalidationFilterTresholdConfidence {
                failCount = 0
                result = FilterResult(position: location, previousPosition: previous, type: .valid, speedRadius: d, confidence: c)
                result?.fromLastRefuse = fromLastRefuse
                result?.previousBadPosition = previousBad
            } else {
                failCount = failCount + 1
                result = FilterResult(position: location, previousPosition: previous, type: .invalid, speedRadius: d, confidence: c)
                result?.previousBadPosition = previousBad
                if failCount > 2 {
                    // au bout de 3 refus on reinitialise le filtre et on repart sur de nouvelles bases
                    reset()
                }
            }
        }
        for d in LocationValidator.delegates {
            d.didRunEstimation(result)
        }
        return result
    }

    // MARK: actions
    public func reset() {
        // reset  -> filter will be reinitilized next time
        proximityFilter?.reset()
        failCount = 0
    }

    // MARK: AppState delegation
    public func onAppInForeground() {
        reset()
        isInFG = true
    }

    public func onAppInBackground() {
        reset()
        isInFG = false
    }
}

@objc public class FilterResult: NSObject {

    public var previousPosition: CLLocation?
    public var previousBadPosition: CLLocation?
    public var position: CLLocation
    public var type: ResultType
    public var distance: Double?
    public var validRadius: Double = 0
    public var confidence: Double = 0
    public var fromLastRefuse = false

    fileprivate   init( position: CLLocation, previousPosition: CLLocation?, type: ResultType, speedRadius: Double, confidence: Double ) {
        self.position = position
        self.type = type
        self.validRadius = speedRadius
        self.confidence = confidence
        self.previousPosition = previousPosition
    }
// used for tests
    public init(position: CLLocation) {
        self.position = position
        self.type = .valid
    }
}
