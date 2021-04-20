//
//  LogDataRedirect.swift
//  herow_sdk_ios
//
//  Created by Damien on 19/04/2021.
//

import Foundation
class LogDataNotification: LogData {
    var campaignId: String?
    var campaignName: String?
    var isPersistentNotification: Bool?
    var isExitNotification: Bool?
    var subType: SubType
    var zoneID: String
    init( appState: String,
          campaignId: String?,
          campaignName: String?,
          isPersistentNotification: Bool? ,
          isExitNotification: Bool,
          cacheManager: CacheManagerProtocol,
          dataStorage: HerowDataStorageProtocol?, subType: SubType, zoneID: String) {
        self.campaignId = campaignId
        self.campaignName = campaignName
        self.isPersistentNotification = isPersistentNotification
        self.isExitNotification = isExitNotification
        self.subType = subType
        self.zoneID = zoneID
        super.init(appState: appState, cacheManager: cacheManager, dataStorage: dataStorage)
    }
    override func getData() -> Data? {
        let logData = LogDataNotificationStruct( appState: self.appState, subtype: self.subType ,campaignId: self.campaignId,campaignName: self.campaignName,isPersistentNotification: self.isPersistentNotification, isExitNotification: self.isExitNotification, dataStorage: self.dataStorage, zoneID: zoneID)

        let log = Log(data: logData)
        return  log.encode()
    }
}

class LogDataNotificationStruct: LogDataStruct {
    var campaignId: String?
    var campaignName: String?
    var isPersistentNotification: Bool?
    var isExitNotification: Bool?
    var zoneID: String
    init( appState: String,
          subtype: SubType,
          campaignId: String?,
          campaignName: String?,
          isPersistentNotification: Bool? ,
          isExitNotification: Bool?,
          dataStorage: HerowDataStorageProtocol?,
          zoneID: String)  {
        self.zoneID = zoneID
        self.campaignId = campaignId
        self.campaignName = campaignName
        super.init(appState: appState, subtype: subtype.rawValue, dataStorage: dataStorage)

    }

    enum CodingKeys: String, CodingKey {
        case campaignId
        case campaignName
        case isPersistentNotification
        case isExitNotification
        case zoneID = "techno_hash"
    }

    public override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(campaignId, forKey: .campaignId)
        try container.encodeIfPresent(campaignName, forKey: .campaignName)
        try container.encodeIfPresent(isPersistentNotification, forKey: .isPersistentNotification)
        try container.encodeIfPresent(isExitNotification, forKey: .isExitNotification)
        try container.encode(zoneID, forKey: .zoneID)
    }
}
