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

    init(location: CLLocation?, zones:[Zone]) {
        self.location = location
        self.zones = zones
    }
}

@objc public class ZoneInfo: NSObject, Codable {
    public var zoneHash: String
    public var enterTime: TimeInterval? = 0
    public var exitTime: TimeInterval? = 0
    public var enterLocation: CLLocationCoordinate2D?
    public var exitLocation: CLLocationCoordinate2D?
    init(hash: String) {
        self.zoneHash = hash
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
    var dataHolder = DataHolderUserDefaults(suiteName: "ZoneEventGenerator")
    var eventDisPatcher: EventDispatcher
    let serialQueue = DispatchQueue(label: "ZoneEventGenerator.serial.queue")
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    var isComputing = false
    var history :[ZoneInfo]?
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

    private func savePlaceHistory(_ zoneInfos: [ZoneInfo]) {
        history = zoneInfos
        if let data = try? encoder.encode(zoneInfos) {
            dataHolder.putData(key: ZoneEventGenerator.keyZoneEventHistory, value: data)
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
            let currentLocation = forZones.location

            let zonesLocationIds = zones.map {
                $0.getHash()
            }
            let oldZonesIds = getPlaceHistory().map {$0.zoneHash}

            let input: [ZoneInfo] = zones.map {
                let zoneInfo = getOldZoneInfoFor(hash: $0.getHash())
                let new = ZoneInfo(hash: $0.getHash() )
                new.enterLocation = currentLocation?.coordinate
                new.enterTime = now
                let result = zoneInfo ?? new
                return result
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
            }

            let entriesids = entries.map {
                return $0.zoneHash
            }
            let exitesids = exits.map {
                return $0.zoneHash
            }
            savePlaceHistory(input)
            GlobalLogger.shared.verbose("ZoneEventGenerator computeEvents oldZonesIds =\(oldZonesIds.count), entries=\(entriesids), exits=\(exitesids)")
            DispatchQueue.global().async {
                eventDisPatcher.post(event: .GEOFENCE_ENTER, infos: entries)
                eventDisPatcher.post(event: .GEOFENCE_EXIT, infos: exits)
                eventDisPatcher.post(event: .GEOFENCE_VISIT, infos: exits)
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
        let container =  SelectionContainer(location: location, zones: entrances)
        zoneEventGenerator.computeEvents(forZones: container)
        return container
    }


    func onCacheUpdate() {
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
