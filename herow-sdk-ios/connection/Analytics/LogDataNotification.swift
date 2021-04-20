//
//  LogDataRedirect.swift
//  herow_sdk_ios
//
//  Created by Damien on 19/04/2021.
//

import Foundation
class LogDataRedirect: LogData {
    var campaignId: String?
    var campaignName: String?
    var isPersistentNotification: Bool?
    var isExitNotification: Bool?


    init( appState: String,
          campaignId: String?,
          campaignName: String?,
          isPersistentNotification: Bool? ,
          isExitNotification: Bool,
          cacheManager: CacheManagerProtocol,
          dataStorage: HerowDataStorageProtocol?) {
        self.campaignId = campaignId
        self.campaignName = campaignName
        self.isPersistentNotification = isPersistentNotification
        self.isExitNotification = isExitNotification
        super.init(appState: appState, cacheManager: cacheManager, dataStorage: dataStorage)
    }
    override func getData() -> Data? {
        let logData = LogDataRedirectStruct( appState: self.appState, subtype:  "NOTIFICATION_REDIRECT" ,campaignId: self.campaignId,campaignName: self.campaignName,isPersistentNotification: self.isPersistentNotification, isExitNotification: self.isExitNotification, dataStorage: self.dataStorage)

        let log = Log(data: logData)
        return  log.encode()
    }
}

class LogDataRedirectStruct: LogDataStruct {
    var campaignId: String?
    var campaignName: String?
    var isPersistentNotification: Bool?
    var isExitNotification: Bool?

    init( appState: String,
          subtype: String,
          campaignId: String?,
          campaignName: String?,
          isPersistentNotification: Bool? ,
          isExitNotification: Bool?,
          dataStorage: HerowDataStorageProtocol?)  {
        self.campaignId = campaignId
        self.campaignName = campaignName
        super.init(appState: appState, subtype: subtype, dataStorage: dataStorage)

    }

    enum CodingKeys: String, CodingKey {
        case campaignId
        case campaignName
        case isPersistentNotification
        case isExitNotification
    }

    public override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(campaignId, forKey: .campaignId)
        try container.encodeIfPresent(campaignName, forKey: .campaignName)
        try container.encodeIfPresent(isPersistentNotification, forKey: .isPersistentNotification)
        try container.encodeIfPresent(isExitNotification, forKey: .isExitNotification)
    }
}
