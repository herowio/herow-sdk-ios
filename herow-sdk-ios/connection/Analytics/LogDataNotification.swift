//
//  LogDataRedirect.swift
//  herow_sdk_ios
//
//  Created by Damien on 19/04/2021.
//

import Foundation
import CoreLocation
class LogDataNotification: LogData {
    var campaignId: String?
    var subType: SubType
    var zoneID: String
    var zoneInfo: ZoneInfo?
    init( appState: String,
          campaignId: String?,
          cacheManager: CacheManagerProtocol,
          dataStorage: HerowDataStorageProtocol?, subType: SubType, zoneID: String, zoneInfo: ZoneInfo?) {
        self.campaignId = campaignId

        self.subType = subType
        self.zoneID = zoneID
        self.zoneInfo = zoneInfo
        super.init(appState: appState, cacheManager: cacheManager, dataStorage: dataStorage)
    }
    override func getData() -> Data? {
        let logData = LogDataNotificationStruct( appState: self.appState, subtype: self.subType ,campaignId: self.campaignId, dataStorage: self.dataStorage, cacheManager: cacheManager, zoneID: zoneID, zoneInfo: zoneInfo)

        let log = Log(data: logData)
        return  log.encode()
    }
}

class LogDataNotificationStruct: LogDataStruct {
    var campaignId: String?
    var zoneID: String
    var zoneInfo: ZoneInfo?
    var place : NearbyPlace?
    var lastLocation: CLLocation?
    init( appState: String,
          subtype: SubType,
          campaignId: String?,
          dataStorage: HerowDataStorageProtocol?,
          cacheManager: CacheManagerProtocol?,
          zoneID: String, zoneInfo: ZoneInfo?)  {

        lastLocation = subtype  == .GEOFENCE_ZONE_NOTIFICATION ? CLLocationManager().location : nil
        self.zoneID = zoneID
        self.campaignId = campaignId
        self.zoneInfo = zoneInfo

        if let zone = cacheManager?.getZones(ids: [self.zoneID]).first {
            let lat = zone.getLat()
            let lng = zone.getLng()
            let center = CLLocation(latitude: lat, longitude: lng)
            let distance = lastLocation?.distance(from: center) ?? 0

            self.place = NearbyPlace(placeId: zone.getHash(), distance: distance, radius: zone.getRadius(), lat: lat, lng: lng, confidence: zoneInfo?.confidence ?? 0)
        }
        super.init(appState: appState, subtype: subtype.rawValue, dataStorage: dataStorage)


    }

    enum CodingKeys: String, CodingKey {
        case campaignId = "campaign_id"
        case zoneID = "techno_hash"
        case place
        case lastLocation
    }

    public override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(campaignId, forKey: .campaignId)
        try container.encode(zoneID, forKey: .zoneID)
        try container.encodeIfPresent(place, forKey: .place)
        try container.encodeIfPresent(lastLocation, forKey: .lastLocation)
    }
}
