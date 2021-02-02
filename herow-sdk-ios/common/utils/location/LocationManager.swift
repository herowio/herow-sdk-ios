//
//  LocationManager.swift
//  ConnectPlaceCommon
//
//  Created by Connecthings on 16/01/2018.
//  Copyright © 2018 Connecthings. All rights reserved.
//

import Foundation
import CoreLocation

/// To launch monitoring and ranging in beaconRegion

@objc public protocol ClickAndConnectListener {
    func didStopClickAndConnect()
    func didStartClickAndConnect()
}

public protocol LocationManager {

    var location: CLLocation? { get }

    var heading: CLHeading? { get }

    var delegate: CLLocationManagerDelegate? { get set }

    var pausesLocationUpdatesAutomatically: Bool { get set }

    var allowsBackgroundLocationUpdates: Bool { get set }

    var distanceFilter: CLLocationDistance { get set }

    var desiredAccuracy: CLLocationAccuracy { get set }

    var activityType: CLActivityType { get set }

    var showsBackgroundLocationIndicator: Bool {get set}
    /// Request the authorization to the User to use the location in background and foreground
    ///
    func requestAlwaysAuthorization()

    /// To get the authorization status
    ///
    /// - Returns: the current authorization status
    func authorizationStatus() -> CLAuthorizationStatus
    /// To get the authorization status string
    ///
    /// - Returns: the current authorization status description
    func authorizationStatusString() -> String

    /// To get the authorization status string
    ///
    /// - Returns: the current  accuracy authorization status description
    func accuracyAuthorizationStatusString() -> String
    /// To check which accuracy is allowed
    ///
    /// - Returns: true if the location services are enabled
    func locationServicesEnabled() -> Bool

    /// To start monitoring in this region
    ///
    /// - Parameter region: a beacon region to monitor
    func startMonitoring(region: CLRegion)

    /// To stop monitoring in this region
    ///
    /// - Parameter region: a beacon region to stop monitoring
    func stopMonitoring(region: CLRegion)


    /// To get the list of regions currently monitored by the Manager
    ///
    /// - Returns: the monitored regions
    func getMonitoredRegions() -> Set<CLRegion>


    /*
     *  startMonitoringSignificantLocationChanges
     *
     *  Discussion:
     *      Start monitoring significant location changes.  The behavior of this service is not affected by the desiredAccuracy
     *      or distanceFilter properties.  Locations will be delivered through the same delegate callback as the standard
     *      location service.
     *
     */
    func startMonitoringSignificantLocationChanges()
    /*
     *  stopMonitoringSignificantLocationChanges
     *
     *  Discussion:
     *      Stop monitoring significant location changes.
     *
     */
    func stopMonitoringSignificantLocationChanges()
    /*
     *  startUpdatingLocation
     *
     *  Discussion:
     *      Start updating locations.
     */
    func startUpdatingLocation()
    /*
     *  stopUpdatingLocation
     *
     *  Discussion:
     *      Stop updating locations.
     */
    func stopUpdatingLocation()
    /*
     *  startMonitoringVisits
     *
     *  Discussion:
     *    Begin monitoring for visits.  All CLLLocationManagers allocated by your
     *    application, both current and future, will deliver detected visits to
     *    their delegates.  This will continue until -stopMonitoringVisits is sent
     *    to any such CLLocationManager, even across application relaunch events.
     *
     *    Detected visits are sent to the delegate's -locationManager:didVisit:
     *    method.
     */
    func startMonitoringVisits()
    /*
     *  stopMonitoringVisits
     *
     *  Discussion:
     *    Stop monitoring for visits.  To resume visit monitoring, send
     *    -startMonitoringVisits.
     *
     *    Note that stopping and starting are asynchronous operations and may not
     *    immediately reflect in delegate callback patterns.
     */
    func stopMonitoringVisits()

    func registerClickAndCollectListener(listener: ClickAndConnectListener)

    func unregisterClickAndCollectListener(listener: ClickAndConnectListener)

    func registerDetectionListener(listener: DetectionEngineListener)

    func unregisterDetectionListener(listener: DetectionEngineListener)
    
    func updateClickAndCollectState()

    func setIsOnClickAndCollect(_ value: Bool)
}

extension LocationManager {


    public mutating func  activeClickAndCollectMode( mode : Bool) {
        setIsOnClickAndCollect(mode)
        updateClickAndCollectState()
    }
    
    public  mutating func updateBackGroundLocationMode() {
     let backgroundMode = configureBackgroundLocationUpdates()
         allowsBackgroundLocationUpdates = backgroundMode
     //    showsBackgroundLocationIndicator = backgroundMode
         pausesLocationUpdatesAutomatically = false

     }

    public func configureBackgroundLocationUpdates() -> Bool {
         if let array: [String] = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String] {
             GlobalLogger.shared.info("The location manager is allowed to run in background")
             return array.contains("location") &&  UserDefaults.standard.bool(forKey: "allowsBackgroundLocationUpdates")
         }
         GlobalLogger.shared.info("The location manager is NOT allowed to run in background")
         return false
     }



}


