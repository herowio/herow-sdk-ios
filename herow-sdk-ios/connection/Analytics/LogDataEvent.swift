//
//  LogDataEvent.swift
//  herow-sdk-ios
//
//  Created by Damien on 01/02/2021.
//

import Foundation
import CoreLocation
class LogDataEvent: LogData {
    let event: Event
    let infos: ZoneInfo


    init(appState: String,  event: Event, infos: ZoneInfo, cacheManager: CacheManagerProtocol, dataStorage: HerowDataStorageProtocol? ) {
        self.event = event
        self.infos = infos
        super.init(appState: appState, cacheManager: cacheManager, dataStorage: dataStorage)
    }

    override func getData() -> Data? {
        let logData = LogDataEventStruct(event: event, infos: infos, appState: appState, dataStorage: dataStorage, cacheManager: cacheManager)
        let log = Log(data: logData)
        return  log.encode()
    }
}

class LogDataEventStruct: LogDataStruct {
    let lastLocation: CLLocation?
    var place: NearbyPlace? = nil
    var duration: TimeInterval? = nil

    init(event: Event, infos: ZoneInfo, appState: String, dataStorage: HerowDataStorageProtocol?,cacheManager: CacheManagerProtocol?)  {
        lastLocation = CLLocationManager().location

        if let zone = infos.getZone() { //cacheManager?.getZones(ids: [infos.zoneHash]).first {
            let lat = zone.getLat()
            let lng = zone.getLng()
            let center = CLLocation(latitude: lat, longitude: lng)
            let distance = lastLocation?.distance(from: center) ?? 0
            if event == .GEOFENCE_VISIT ,let entrance = infos.enterTime, let exit = infos.exitTime {
                self.duration = (exit - entrance) * 1000
            }
            self.place = NearbyPlace(placeId: zone.getHash(), distance: distance, radius: zone.getRadius(), lat: lat, lng: lng, confidence: infos.confidence)
        }

        super.init(appState: appState, subtype: event.toString(), dataStorage: dataStorage)

    }

    enum CodingKeys: String, CodingKey {
        case lastLocation
        case place
        case duration

    }

    public override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(lastLocation, forKey: .lastLocation)
        try container.encodeIfPresent(place, forKey: .place)
        try container.encodeIfPresent(duration, forKey: .duration)
    }
}
