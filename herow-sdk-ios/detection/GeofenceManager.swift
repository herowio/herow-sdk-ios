//
//  GeofenceManager.swift
//  herow-sdk-ios
//
//  Created by Damien on 27/01/2021.
//
import Foundation
import CoreLocation

fileprivate struct MovingGeofenceParameter {
    fileprivate var distanceFromNearestPlace: CLLocationDistance
    fileprivate let circleRadiusOfRegion: CLLocationDistance
    fileprivate let distanceFromUserToRegionBorder: CLLocationDistance

    init(distanceFromNearestPlace: CLLocationDistance,
         circleRadiusOfMovingRegion: CLLocationDistance,
         distanceFromUserForBorderOfMovingRegion: CLLocationDistance) {
        self.distanceFromNearestPlace = distanceFromNearestPlace
        self.circleRadiusOfRegion = circleRadiusOfMovingRegion
        self.distanceFromUserToRegionBorder = distanceFromUserForBorderOfMovingRegion
    }
}
class GeofenceManager: CacheListener, DetectionEngineListener {

    private let movingRegionBearings: [Double] = [0, 90, 180, 270]
    private let maxGeoFenceZoneCount = 10
    internal private(set) var lastLocation: CLLocation?

    fileprivate let movingGeofenceParameter: MovingGeofenceParameter = MovingGeofenceParameter(distanceFromNearestPlace: 0,
                                              circleRadiusOfMovingRegion: 150,
                                distanceFromUserForBorderOfMovingRegion: 100)
    private var currentParametersPosition: Int = 0
    private let locationManager: LocationManager
    private let cacheManager : CacheManagerProtocol

    init(locationManager: LocationManager, cacheManager: CacheManagerProtocol) {
        self.locationManager = locationManager
        self.cacheManager = cacheManager
    }

    private func startMonitoringRegion(_ region: CLRegion) {
        locationManager.startMonitoring(region: region)
    }

    private func stopMonitoringRegions(_ regions: [CLRegion]) {
        for region in regions {
            locationManager.stopMonitoring(region: region)
        }
    }


    private func createPlaceRegions( places: [Zone]) {
        for place in places {
            let placeLocation = CLLocation(latitude: place.getLat(), longitude: place.getLng())
            let region = createRegion(center: placeLocation, radius: place.getRadius(), prefix: "zone",zoneHash: place.getHash())
            startMonitoringRegion(region)
        }
    }

    private func cleanPlaceMonitoredRegions( places: [Zone]) -> [Zone] {
        let monitoredRegions = locationManager.getMonitoredRegions()
        let monitoredIds = monitoredRegions.map {getPlaceIdForRegion($0)}
        let idsToKeep = places.map {$0.getHash()}
        let idsToUnMonitor = monitoredIds.filter {!(idsToKeep.contains($0 as String) || $0.hasPrefix(LocationUtils.regionIdPrefix + ".moving."))}
        let regionToUnMonitor = monitoredRegions.filter {
            idsToUnMonitor.contains(getPlaceIdForRegion($0))
        }
        for region in regionToUnMonitor {
          locationManager.stopMonitoring(region: region)
        }
        let nowMonitoredRegionsIds = locationManager.getMonitoredRegions().map {getPlaceIdForRegion($0)}
        return places.filter { !nowMonitoredRegionsIds.contains($0.getHash() as NSString)}
    }

    private  func createRegion(center: CLLocation, radius: CLLocationDistance, prefix: String, zoneHash: String = "") -> CLRegion {
        let identifier: String = LocationUtils.regionIdPrefix + "." + prefix + ".\(center.coordinate.latitude).\(center.coordinate.longitude).\(zoneHash)"
        let region = CLCircularRegion(center: center.coordinate, radius: radius, identifier: identifier)
        region.notifyOnExit = true
        region.notifyOnEntry = true
        return region
    }

    private func getPlaceIdForRegion(_ region: CLRegion) -> NSString {
        var  placeId = ""
        if region is CLCircularRegion {
            if let circularRegion  = region as? CLCircularRegion {
                let identifier: String = region.identifier
                let prefix = LocationUtils.regionIdPrefix + ".zone." + "\(circularRegion.center.latitude).\(circularRegion.center.longitude)."
                placeId = identifier.replacingOccurrences(of: prefix, with: "")
            }
        }
        return placeId as NSString
    }

    private func isMovingRegion(_ region: CLRegion) -> Bool {
        return region.identifier.hasPrefix(LocationUtils.regionIdPrefix + ".moving.")
    }

    private func updateRegions(location: CLLocation)
      {
        lastLocation = location
        let regionsRecord = selectMovingGeofenceRegions(location: location)
        for region in regionsRecord.regionsToRemove {
            self.locationManager.stopMonitoring(region: region)
        }
        GlobalLogger.shared.debug("geofenceMoving - regionsToRemove: \(regionsRecord.regionsToRemove)")

        if regionsRecord.update() {

            GlobalLogger.shared.debug("geofenceMoving - create new regions")
            createNewMovingGeofences(location: location)
        }
    }

   private func selectMovingGeofenceRegions(location: CLLocation) -> MovingRegionRecord {
        let movingRegionsRecord: MovingRegionRecord = MovingRegionRecord()
        var doUpdate: Bool = false
        var minLat: Double = Double.greatestFiniteMagnitude
        var minLng: Double = Double.greatestFiniteMagnitude
        var maxLat: Double = Double.leastNormalMagnitude
        var maxLng: Double = Double.leastNormalMagnitude

        for region in locationManager.getMonitoredRegions() where isMovingRegion(region) {
            movingRegionsRecord.regionsToRemove.append(region)
            movingRegionsRecord.areMonitoredRegions = true
            if let region: CLCircularRegion = region as? CLCircularRegion {
                if region.contains(location.coordinate) {
                    doUpdate = true
                }
                minLat = min(minLat, region.center.latitude)
                maxLat = max(maxLat, region.center.latitude)
                minLng = min(minLng, region.center.longitude)
                maxLng = max(maxLng, region.center.longitude)
            }
        }

        if !doUpdate {
            // Test if the location is outside fomr the square
            // if it's the case it keeps the movingRegions to remove them all
            var removeAll = true
            let coordinate = location.coordinate
            // If the point is outside of the square we update
            if minLat > coordinate.latitude ||
                maxLat < coordinate.latitude ||
                minLng > coordinate.longitude ||
                maxLng < coordinate.longitude {
                    removeAll = false
            }
            if removeAll {
                movingRegionsRecord.regionsToRemove.removeAll()
            }
        }
        return movingRegionsRecord
    }

    private func getDistanceFromNearestPlace(location: CLLocation, nearestPlace: Zone) -> CLLocationDistance {
        let placeLocation = CLLocation(latitude: nearestPlace.getLat(), longitude: nearestPlace.getLng())
        return location.distance(from:placeLocation)


    }

    private func createNewMovingGeofences(location: CLLocation) {
        let movingDistance = calculateDistanceFromCenter(parameter: movingGeofenceParameter)
        let radius = calculateRegionRadius(parameter: movingGeofenceParameter)
        for bearing in movingRegionBearings {
            let geofenceLocation: CLLocation = LocationUtils.location(location: location,
                                                                      byMovingDistance: movingDistance,
                                                                      withBearing: bearing)
            let region = createRegion(center: geofenceLocation,
                                      radius: radius, prefix: "moving")
            startMonitoringRegion(region)
        }
    }

    private func calculateRegionRadius(parameter: MovingGeofenceParameter) -> Double {
        //return parameter.circleRadiusOfRegion
        return parameter.distanceFromUserToRegionBorder * 2
    }

    private func calculateDistanceFromCenter(parameter: MovingGeofenceParameter) -> Double {
        //return  parameter.distanceFromUserToRegionBorder * 4
        return parameter.distanceFromUserToRegionBorder * 3
    }

    func onCacheUpdate() {
            updateMonitoringFor(location: lastLocation)
    }

    func updateMonitoringFor(location: CLLocation?) {
        var zones : [Zone]
        if let location = location {
            updateRegions(location: location)
            zones = cacheManager.getNearbyZones(location)
            zones = Array(zones.sorted { (initial, next) -> Bool in
                return initial.distanceFrom(location: location) < next.distanceFrom(location: location)
                }.prefix(maxGeoFenceZoneCount))
        } else {
            zones = [Zone]()
        }
        createPlaceRegions(places: cleanPlaceMonitoredRegions(places: zones))
    }

    func onLocationUpdate(_ location: CLLocation) {
        updateMonitoringFor(location: location)
    }

    func reset() {
        for region in locationManager.getMonitoredRegions() {
            if !isMovingRegion(region) {
                locationManager.stopMonitoring(region: region)
            }
        }
    }
}

fileprivate class MovingRegionRecord {
    var regionsToRemove: [CLRegion]
    var areMonitoredRegions: Bool

    init() {
        regionsToRemove = []
        areMonitoredRegions = false
    }

    func update() -> Bool {
        return regionsToRemove.count > 0 || !areMonitoredRegions
    }
}
