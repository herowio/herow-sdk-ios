//
//  ZoneProvider.swift
//  herow-sdk-ios
//
//  Created by Damien on 27/01/2021.
//

import Foundation
import CoreData
import CoreLocation

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
    public var poisNames: [String]?
    var zone: HerowZone?
    
    init(zone: Zonable) {
        self.zoneHash = zone.getHash()
        self.radius = zone.getRadius()
        self.centerLocation = CLLocationCoordinate2D(latitude: zone.getLat(), longitude:  zone.getLng())
        if let myZone = zone as? HerowZone {
            self.zone = myZone
        }
        if let node = zone as? QuadTreeNode {
            poisNames =  Array(node.getPois().map {
                $0.getTags()
            }.joined())
        }
    }

    public func getZone() -> HerowZone? {
        return zone
    }

    func computeEnterConfidence(location: CLLocation)  {

        let center = CLLocation(latitude: centerLocation.latitude, longitude: centerLocation.longitude)
        confidence = LocationUtils.computeConfidence(centerLocation: center, location: location, radius: radius ?? 0)
        GlobalLogger.shared.debug("ZoneInfo enter confidence : \(confidence ?? 0)")
    }

    func computeNotificationConfidence(location: CLLocation)  {
        let center = CLLocation(latitude: centerLocation.latitude, longitude: centerLocation.longitude)
        confidence = LocationUtils.computeConfidence(centerLocation: center ,location: location, radius: 3 * (radius ?? 0))
        GlobalLogger.shared.debug("ZoneInfo enter notification zone confidence : \(confidence ?? 0)")
    }

    func computeExitConfidence(location: CLLocation)  {
        let center = CLLocation(latitude: centerLocation.latitude, longitude: centerLocation.longitude)
        confidence =  1 - LocationUtils.computeConfidence(centerLocation: center, location: location, radius: radius ?? 0)
        GlobalLogger.shared.debug("ZoneInfo exit zone confidence : \(confidence ?? 0)")
    }
}


extension Double {
    func round(to places: Int) -> Double {
        return Double(String(format: "%.\(places)f", self))!
    }
}

extension Float {
    func round(to places: Int) -> Float {
        return Float(String(format: "%.\(places)f", self))!
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
    static let keyZoneEventHistory = "com.herow.keyZoneEventHistory"
    static let keyNotificationZoneEventHistory = "com.herow.keyNotificationZoneEventHistory"
    static let keyHomeZoneEventHistory = "com.herow.keyHomeZoneEventHistory"
    static let keyWorkZoneEventHistory = "com.herow.keyWorkZoneEventHistory"
    static let keySchoolZoneEventHistory = "com.herow.keySchoolZoneEventHistory"
    static let keyShopZoneEventHistory = "com.herow.keyShopZoneEventHistory"

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

    func computeEventForHome(_ node : QuadTreeNode, enter: Bool) {
        let last = dataHolder.getBoolean(key: ZoneEventGenerator.keyHomeZoneEventHistory)
        if !last && enter {
            let zoneInfos = ZoneInfo(zone: node)
            zoneInfos.enterTime = Date().timeIntervalSince1970
            eventDisPatcher.post(event: .LIVE_HOME, infos: [zoneInfos])
        }
        dataHolder.putBoolean(key:  ZoneEventGenerator.keyHomeZoneEventHistory, value: enter)
    }

    func computeEventForWork(_ node : QuadTreeNode, enter: Bool) {
        let last = dataHolder.getBoolean(key: ZoneEventGenerator.keyWorkZoneEventHistory)
        if !last && enter {
            let zoneInfos = ZoneInfo(zone: node)
            zoneInfos.enterTime = Date().timeIntervalSince1970
            eventDisPatcher.post(event: .LIVE_WORK, infos: [zoneInfos])
        }
        dataHolder.putBoolean(key:  ZoneEventGenerator.keyWorkZoneEventHistory, value: enter)
    }

    func computeEventForSchool(_ node : QuadTreeNode, enter: Bool) {
        let last = dataHolder.getBoolean(key: ZoneEventGenerator.keySchoolZoneEventHistory)
        if !last && enter {
            let zoneInfos = ZoneInfo(zone: node)
            zoneInfos.enterTime = Date().timeIntervalSince1970
            eventDisPatcher.post(event: .LIVE_SCHOOL, infos: [zoneInfos])
        }
        dataHolder.putBoolean(key:  ZoneEventGenerator.keySchoolZoneEventHistory, value: enter)
    }

    func computeEventForShopping(_ node : QuadTreeNode, enter: Bool) {
        let last = dataHolder.getBoolean(key: ZoneEventGenerator.keyShopZoneEventHistory)
        if !last && enter {
            let zoneInfos = ZoneInfo(zone: node)
            zoneInfos.enterTime = Date().timeIntervalSince1970
            eventDisPatcher.post(event: .LIVE_SHOP, infos: [zoneInfos])
        }
        dataHolder.putBoolean(key:  ZoneEventGenerator.keyShopZoneEventHistory, value: enter)
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
            let zonesNotificationsLocationIds = notificationZones.map {
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

            let notificationsExits: [ZoneInfo] = getPlaceNotificationHistory().filter {
                !zonesNotificationsLocationIds.contains($0.zoneHash)
            }

            for info in exits {
                info.exitLocation = currentLocation?.coordinate
                info.exitTime = now
                if let currentLocation = currentLocation {
                    info.computeExitConfidence(location: currentLocation)
                }
            }

            for info in notificationsExits {
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

            GlobalLogger.shared.debug("ZoneEventGenerator computeEvents oldZonesIds =\(oldZonesIds.count), entries=\(entriesids), exits=\(exitesids)")
            DispatchQueue.global().async {
                eventDisPatcher.post(event: .GEOFENCE_ENTER, infos: entries)
                eventDisPatcher.post(event: .GEOFENCE_EXIT, infos: exits)
                eventDisPatcher.post(event: .GEOFENCE_VISIT, infos: exits)
                eventDisPatcher.post(event: .GEOFENCE_NOTIFICATION_ZONE_ENTER, infos: notificationEntries)
                eventDisPatcher.post(event: .GEOFENCE_NOTIFICATION_ZONE_EXIT, infos: notificationsExits)
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
class ZoneProvider: DetectionEngineListener, CacheListener, LiveMomentStoreListener {

    var home : QuadTreeNode?
    var work : QuadTreeNode?
    var school: QuadTreeNode?
    var shoppings: [QuadTreeNode]?
    func liveMomentStoreStartComputing() {
        // do nothing
    }

    func didCompute(rects: [NodeDescription]?, home: QuadTreeNode?, work: QuadTreeNode?, school: QuadTreeNode?, shoppings: [QuadTreeNode]?, others: [QuadTreeNode]?, neighbours: [QuadTreeNode]?, periods: [PeriodProtocol]) {
        self.home = home
        self.work = work
        self.school = school
        self.shoppings = shoppings
    }

    func getFirstLiveMoments(home: QuadTreeNode?, work: QuadTreeNode?, school: QuadTreeNode?, shoppings: [QuadTreeNode]?) {
        self.home = home
        self.work = work
        self.school = school
        self.shoppings = shoppings
    }

    func didChangeNode(node: QuadTreeNode) {
        // do nothing
    }

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
            zoneDetectionProcess(location)
            liveMomentProcess(location)
        } else {
            GlobalLogger.shared.warning("don't process because cache not updated")
        }
    }

    @discardableResult
    func zoneDetectionProcess(_ location: CLLocation) -> SelectionContainer {
        let entrances = zonesForLocation(location)
        let notificationZonesEntrances = notificationZonesForLocation(location)
        let container =  SelectionContainer(location: location, zones: entrances, notificationZones: notificationZonesEntrances)
        zoneEventGenerator.computeEvents(forZones: container)
        return container
    }

    func liveMomentProcess(_ location: CLLocation) {
        if let home = self.home {
            let circle = home.getRect().circle()
            let center = CLLocation(latitude:circle.center.latitude, longitude: circle.center.longitude)
            let distance  = center.distance(from: location)
            zoneEventGenerator.computeEventForHome(home, enter:  circle.radius >= distance)
        }
        if let work = self.work {
            let circle = work.getRect().circle()
            let center = CLLocation(latitude:circle.center.latitude, longitude: circle.center.longitude)
            let distance  = center.distance(from: location)
            zoneEventGenerator.computeEventForWork(work, enter:  circle.radius >= distance)
        }
        if let school = self.school {
            let circle = school.getRect().circle()
            let center = CLLocation(latitude:circle.center.latitude, longitude: circle.center.longitude)
            let distance  = center.distance(from: location)
            zoneEventGenerator.computeEventForSchool(school, enter:  circle.radius >= distance)
        }
        if let shoppings = self.shoppings {
            for shop in shoppings{
                let circle = shop.getRect().circle()
                let center = CLLocation(latitude:circle.center.latitude, longitude: circle.center.longitude)
                let distance  = center.distance(from: location)
                zoneEventGenerator.computeEventForShopping(shop, enter:  circle.radius >= distance)
            }
        }
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
