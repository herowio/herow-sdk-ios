//
//  ZoneProvider.swift
//  herow-sdk-ios
//
//  Created by Damien on 27/01/2021.
//

import Foundation
import CoreData
public protocol ZoneventListener {

}

class SelectionContainer {
    let location: CLLocation?
    let zones: [Zone]

    init(location: CLLocation?, zones:[Zone]) {
        self.location = location
        self.zones = zones
    }
}

class ZoneInfo: Codable {
    public var hash: String
    public var enterTime: TimeInterval? = 0
    public var exitTime: TimeInterval? = 0
    public var enterLocation: CLLocationCoordinate2D?
    public var exitLocation: CLLocationCoordinate2D?
    init(hash: String) {
        self.hash = hash
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

    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    init(eventDisPatcher: EventDispatcher) {
        self.eventDisPatcher = eventDisPatcher
    }

    private func getPlaceHistory() -> [ZoneInfo] {

        guard let data = dataHolder.getData(key: ZoneEventGenerator.keyZoneEventHistory) ,  let zoneInfos = try? decoder.decode([ZoneInfo].self, from: data) else {
            return [ZoneInfo]()
        }
        return zoneInfos
    }

    private func savePlaceHistory(_ zoneInfos: [ZoneInfo]) {
        if let data = try? encoder.encode(zoneInfos) {
            dataHolder.putData(key: ZoneEventGenerator.keyZoneEventHistory, value: data)
            dataHolder.apply()
        } else {
            GlobalLogger.shared.debug("ZoneEventGenerator - encoding error")
        }
    }



     func computeEvents(forZones: SelectionContainer) {
        let now = Date().timeIntervalSince1970
        let zones: [Zone] = forZones.zones
        let currentLocation = forZones.location

        let zonesLocationIds = zones.map {
            $0.getHash()
        }
        let oldZonesIds = getPlaceHistory().map {$0.hash}

        let input: [ZoneInfo] = zones.map {
            let zoneInfo = getOldZoneInfoFor(hash: $0.getHash())
            let new = ZoneInfo(hash: $0.getHash() )
            new.enterLocation = currentLocation?.coordinate
            new.enterTime = now
            let result = zoneInfo ?? new
            return result
        }
        let entries: [ZoneInfo] = input.filter {
            !oldZonesIds.contains( $0.hash as String )
        }
        let exits: [ZoneInfo] = getPlaceHistory().filter {
            !zonesLocationIds.contains($0.hash)
        }

        for info in exits {
            info.exitLocation = currentLocation?.coordinate
            info.exitTime = now
        }
        eventDisPatcher.post(event: .GEOFENCE_ENTER, infos: entries)
        eventDisPatcher.post(event: .GEOFENCE_EXIT, infos: exits)
        eventDisPatcher.post(event: .GEOFENCE_VISIT, infos: exits)
        GlobalLogger.shared.debug("LiveEventGenerator computeEvents oldZonesIds =\(oldZonesIds.count), entries=\(entries), exits=\(exits)")

        savePlaceHistory(input)
    }

    func getOldZoneInfoFor(hash: String) -> ZoneInfo? {
        return getPlaceHistory().filter {
            $0.hash == hash
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
    init(cacheManager: CacheManagerProtocol, eventDisPatcher: EventDispatcher) {
        self.cacheManager = cacheManager
        self.zoneEventGenerator = ZoneEventGenerator(eventDisPatcher: eventDisPatcher)
    }

    func zonesForLocation(_ location: CLLocation) -> [Zone] {
        return cacheManager.getNearbyZones(location).filter {
            return  $0.distanceFrom(location: location) <= $0.getRadius()
        }
    }

    func onLocationUpdate(_ location: CLLocation) {
        self.lastLocation = location
        zoneDetectionProcess(location)
    }

    func zoneDetectionProcess(_ location: CLLocation) {
        let entrances = zonesForLocation(location)
        let container =  SelectionContainer(location: location, zones: entrances)
        zoneEventGenerator.computeEvents(forZones: container)
    }


    func onCacheUpdate() {
        if let location = lastLocation{
            zoneDetectionProcess(location)
        }
    }

    func onCacheUpdate(type: CacheUpdate) {

    }

}
