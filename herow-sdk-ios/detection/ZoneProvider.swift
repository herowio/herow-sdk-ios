//
//  ZoneProvider.swift
//  herow-sdk-ios
//
//  Created by Damien on 27/01/2021.
//

import Foundation
import CoreData


class SelectionContainer {
    let location: CLLocation?
    internal let zones: [Zone]
    internal let notificationZones: [Zone]

    init(location: CLLocation?, zones:[Zone],notificationZones: [Zone] ) {
        self.location = location
        self.zones = zones
        self.notificationZones = notificationZones
    }
}

@objc public class ZoneInfo: NSObject, Codable {
    public var zoneHash: String
    public var enterTime: TimeInterval? = 0
    public var exitTime: TimeInterval? = 0
    public var enterLocation: CLLocationCoordinate2D?
    public var exitLocation: CLLocationCoordinate2D?
    public var centerLocation: CLLocationCoordinate2D
    public var confidence: Double?
    public var radius: Double?
    var zone: HerowZone?
    init(zone: Zone) {
        self.zoneHash = zone.getHash()
        self.radius = zone.getRadius()
        self.centerLocation = CLLocationCoordinate2D(latitude: zone.getLat(), longitude:  zone.getLng())
        if let myZone = zone as? HerowZone {
            self.zone = myZone
        }
    }

   public func getZone() -> HerowZone? {
        return zone
    }

    func computeEnterConfidence(location: CLLocation)  {

        confidence = computeConfidence(location: location, radius: radius ?? 0)
        GlobalLogger.shared.debug("ZoneInfo enter confidence : \(confidence ?? 0)")
    }

    func computeNotificationConfidence(location: CLLocation)  {
        confidence = computeConfidence(location: location, radius: 3 * (radius ?? 0))
        GlobalLogger.shared.debug("ZoneInfo enter notification zone confidence : \(confidence ?? 0)")
    }

    func computeExitConfidence(location: CLLocation)  {
        confidence =  1 - computeConfidence(location: location, radius: radius ?? 0)
        GlobalLogger.shared.debug("ZoneInfo exit zone confidence : \(confidence ?? 0)")
    }

    private func computeConfidence(location: CLLocation, radius: Double) -> Double {
        var result: Double = 0
        let center = CLLocation(latitude: centerLocation.latitude, longitude: centerLocation.longitude)
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
        GlobalLogger.shared.debug("confidence : \(result) for zone: \(self.zoneHash) , radius: \(zoneRadius), accuracy: \(accuracyRadius), location:\(location)")
        return result
    }

}


extension Double {
    func round(to places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
extension CLLocationCoordinate2D: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(longitude)
        try container.encode(latitude)
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let longitude = try container.decode(CLLocationDegrees.self)
        let latitude = try container.decode(CLLocationDegrees.self)
        self.init(latitude: latitude, longitude: longitude)
    }

    func distance(from: CLLocationCoordinate2D) -> CLLocationDistance {
        let destination=CLLocation(latitude:from.latitude,longitude:from.longitude)
        return CLLocation(latitude: latitude, longitude: longitude).distance(from: destination)
    }
}
 class ZoneEventGenerator {
    static let keyZoneEventHistory = "com.connecthings.keyZoneEventHistory"
    static let keyNotificationZoneEventHistory = "com.connecthings.keyNotificationZoneEventHistory"
    var dataHolder = DataHolderUserDefaults(suiteName: "ZoneEventGenerator")
    var eventDisPatcher: EventDispatcher
    let serialQueue = DispatchQueue(label: "ZoneEventGenerator.serial.queue")
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    var isComputing = false
    var history :[ZoneInfo]?
    var notificationHistory :[ZoneInfo]?
    var queue = OperationQueue()
    init(eventDisPatcher: EventDispatcher) {
        self.eventDisPatcher = eventDisPatcher
    }

    private func getPlaceHistory() -> [ZoneInfo] {

        if let history = self.history {
            return history
        }
        guard let data = dataHolder.getData(key: ZoneEventGenerator.keyZoneEventHistory) ,  let zoneInfos = try? decoder.decode([ZoneInfo].self, from: data) else {
            return [ZoneInfo]()
        }
        return zoneInfos
    }

    private func getPlaceNotificationHistory() -> [ZoneInfo] {

        if let history = self.notificationHistory {
            return history
        }
        guard let data = dataHolder.getData(key: ZoneEventGenerator.keyNotificationZoneEventHistory) ,  let zoneInfos = try? decoder.decode([ZoneInfo].self, from: data) else {
            return [ZoneInfo]()
        }
        return zoneInfos
    }

    private func savePlaceHistory(_ zoneInfos: [ZoneInfo]) {
        history = zoneInfos
        if let data = try? encoder.encode(zoneInfos) {
            dataHolder.putData(key: ZoneEventGenerator.keyZoneEventHistory, value: data)
            dataHolder.apply()
        } else {
            GlobalLogger.shared.debug("ZoneEventGenerator - encoding error")
        }
    }

    private func savePlaceNotificationHistory(_ zoneInfos: [ZoneInfo]) {
        notificationHistory = zoneInfos
        if let data = try? encoder.encode(zoneInfos) {
            dataHolder.putData(key: ZoneEventGenerator.keyNotificationZoneEventHistory, value: data)
            dataHolder.apply()
        } else {
            GlobalLogger.shared.debug("ZoneEventGenerator - encoding error")
        }
    }

     func computeEvents(forZones: SelectionContainer) {

        let blockOPeration = BlockOperation { [self] in
            let uuid = UUID().uuidString
            GlobalLogger.shared.debug("ZoneEventGenerator - starts operation: \(uuid)")
            let now = Date().timeIntervalSince1970
            let zones: [Zone] = forZones.zones
            let notificationZones: [Zone] = forZones.notificationZones
            let currentLocation = forZones.location
            let zonesLocationIds = zones.map {
                $0.getHash()
            }

            let oldZonesIds = getPlaceHistory().map {$0.zoneHash}
            let oldNotificationZonesIds = getPlaceNotificationHistory().map {$0.zoneHash}

            let input: [ZoneInfo] = zones.map {
                let zoneInfo = getOldZoneInfoFor(hash: $0.getHash())
                let new = ZoneInfo(zone: $0 )
                new.enterLocation = currentLocation?.coordinate
                new.enterTime = now
                if let currentLocation = currentLocation {

                    new.computeEnterConfidence(location: currentLocation)
                }
                let result = zoneInfo ?? new
                return result
            }

            let notificationInput: [ZoneInfo] = notificationZones.map {
                let zoneInfo = getOldNotificationZoneInfoFor(hash: $0.getHash())
                let new = ZoneInfo(zone: $0 )
                new.enterLocation = currentLocation?.coordinate
                new.enterTime = now

                if let currentLocation = currentLocation {
                    new.computeNotificationConfidence(location: currentLocation)
                }
                let result = zoneInfo ?? new
                return result
            }

            let notificationEntries: [ZoneInfo] = notificationInput.filter {
                !oldNotificationZonesIds.contains( $0.zoneHash as String )
            }
            let entries: [ZoneInfo] = input.filter {
                !oldZonesIds.contains( $0.zoneHash as String )
            }
            let exits: [ZoneInfo] = getPlaceHistory().filter {
                !zonesLocationIds.contains($0.zoneHash)
            }

            for info in exits {
                info.exitLocation = currentLocation?.coordinate
                info.exitTime = now
                if let currentLocation = currentLocation {
                    info.computeExitConfidence(location: currentLocation)
                }
            }

            let entriesids = entries.map {
                return $0.zoneHash
            }
            let exitesids = exits.map {
                return $0.zoneHash
            }
            savePlaceHistory(input)
            savePlaceNotificationHistory(notificationInput)

            GlobalLogger.shared.verbose("ZoneEventGenerator computeEvents oldZonesIds =\(oldZonesIds.count), entries=\(entriesids), exits=\(exitesids)")
            DispatchQueue.global().async {
                eventDisPatcher.post(event: .GEOFENCE_ENTER, infos: entries)
                eventDisPatcher.post(event: .GEOFENCE_EXIT, infos: exits)
                eventDisPatcher.post(event: .GEOFENCE_VISIT, infos: exits)
                eventDisPatcher.post(event: .GEOFENCE_NOTIFICATION_ZONE_ENTER, infos: notificationEntries)
            }

            GlobalLogger.shared.debug("ZoneEventGenerator - ends operation: \(uuid)")

        }
        queue.maxConcurrentOperationCount = 1
        queue.addOperation(blockOPeration)

    }

    func getOldZoneInfoFor(hash: String) -> ZoneInfo? {
        return getPlaceHistory().filter {
            $0.zoneHash == hash
        }.first
    }

    func getOldNotificationZoneInfoFor(hash: String) -> ZoneInfo? {
        return getPlaceNotificationHistory().filter {
            $0.zoneHash == hash
        }.first
    }


    public func clear() {
        dataHolder.clear()
        dataHolder.apply()
    }
}
class ZoneProvider: DetectionEngineListener, CacheListener {

    var lastLocation: CLLocation?
    let cacheManager: CacheManagerProtocol
    let zoneEventGenerator: ZoneEventGenerator
    internal var cacheIsLoaded = false
    init(cacheManager: CacheManagerProtocol, eventDisPatcher: EventDispatcher) {
        self.cacheManager = cacheManager
        self.zoneEventGenerator = ZoneEventGenerator(eventDisPatcher: eventDisPatcher)
    }

    func zonesForLocation(_ location: CLLocation) -> [Zone] {
        return cacheManager.getNearbyZones(location).filter {
            return  $0.distanceFrom(location: location) <= $0.getRadius()
        }
    }

    func notificationZonesForLocation(_ location: CLLocation) -> [Zone] {
        return cacheManager.getNearbyZones(location).filter {
            return  $0.distanceFrom(location: location) <= notificationDistanceForZone($0)
        }
    }

    private   func notificationDistanceForZone(_ zone: Zone) -> Double{
        return zone.getRadius() * 3
    }


    func onLocationUpdate(_ location: CLLocation, from: UpdateType) {
        self.lastLocation = location
        if cacheIsLoaded {
            _ =  zoneDetectionProcess(location)
        } else {
            GlobalLogger.shared.warning("don't process because cache not updated")
        }
    }

    func zoneDetectionProcess(_ location: CLLocation) -> SelectionContainer{
        let entrances = zonesForLocation(location)
        let notificationZonesEntrances = notificationZonesForLocation(location)
        let container =  SelectionContainer(location: location, zones: entrances, notificationZones: notificationZonesEntrances)
        zoneEventGenerator.computeEvents(forZones: container)
        return container
    }


    func onCacheUpdate(forGeoHash: String?) {
        GlobalLogger.shared.warning("cache updated")
        cacheIsLoaded = true
        if let location = lastLocation {
           _ =  zoneDetectionProcess(location)
        }
    }

    func willCacheUpdate() {
        cacheIsLoaded = false
        GlobalLogger.shared.warning("cache will update")
    }

}
