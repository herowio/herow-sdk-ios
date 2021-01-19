//
//  LocationDispatcher.swift
//  ConnectPlaceCommon
//
//  Created by Connecthings on 16/01/2018.
//  Copyright © 2018 Connecthings. All rights reserved.
//

import Foundation
import CoreLocation

/// dispatch the result of the CLLocationManagerDelegate to multiple CLLocationManager.
public class LocationDispatcher: NSObject, CLLocationManagerDelegate {
    public private(set) var delegates: [CLLocationManagerDelegate]

    override public init() {
        delegates = []
        super.init()
    }

    /// to add delegate to be notified about the CLLocationManagerDelegate result
    ///
    /// - Parameter delegate: a class implemented the CLLocationManagerDelegate
    public func add(delegate: CLLocationManagerDelegate) {
        delegates.append(delegate)
    }

    public func locationManager(_ manager: CLLocationManager,
                                didRangeBeacons beacons: [CLBeacon],
                                in region: CLBeaconRegion) {
        for delegate in delegates {
            delegate.locationManager?(manager, didRangeBeacons: beacons, in: region)
        }
    }

    public func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        for delegate in delegates {
            delegate.locationManager?(manager, didEnterRegion: region)
        }
    }

    public func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        for delegate in delegates {
            delegate.locationManager?(manager, didExitRegion: region)
        }
    }

    @available(iOS 14.0, *)
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        didChangeStatus(manager)
    }

    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        didChangeStatus(manager)
    }

  private func didChangeStatus( _ manager: CLLocationManager, _ status: CLAuthorizationStatus? =  CLLocationManager.authorizationStatus() ) {
        for delegate in delegates {
            if #available(iOS 14, *) {
                delegate.locationManagerDidChangeAuthorization?(manager)
            } else {
                delegate.locationManager?(manager, didChangeAuthorization: CLLocationManager.authorizationStatus())
            }
        }
    }

    public func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
        for delegate in delegates {
            delegate.locationManagerDidPauseLocationUpdates?(manager)
        }
    }

    public func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {
        for delegate in delegates {
            delegate.locationManagerDidResumeLocationUpdates?(manager)
        }
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for delegate in delegates {
            delegate.locationManager?(manager, didUpdateLocations: locations)
        }
    }

    public func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
        for delegate in delegates {
            delegate.locationManager?(manager, didVisit: visit)
        }
    }
}
