//
//  LogData.swift
//  herow-sdk-ios
//
//  Created by Damien on 01/02/2021.
//

import Foundation
import CoreLocation
class LogData {
    var appState: String
    var cacheManager: CacheManagerProtocol?
    var dataStorage: HerowDataStorageProtocol?
    init( appState: String, cacheManager:CacheManagerProtocol, dataStorage: HerowDataStorageProtocol? ) {
        self.cacheManager = cacheManager
        self.dataStorage = dataStorage
        self.appState = appState
    }

    func getData() -> Data? {
        fatalError("Must Override")
    }
}

class LogDataStruct: Encodable {
    let phoneId: String
    let appState: String
    let libVersion : String
    let date : TimeInterval
    let applicationName: String
    let applicationVersion: String
    let subtype: String
    let ua: String

    init( appState: String, subtype: String, dataStorage: HerowDataStorageProtocol?) {
        let analyticsInfos = AnalyticsInfo()
        self.phoneId = analyticsInfos.deviceInfo.deviceId()
        self.appState = appState
        self.subtype = subtype
        self.libVersion = analyticsInfos.libInfo.version
        self.date = Date().timeIntervalSince1970 * 1000
        self.applicationName = analyticsInfos.appInfo.displayName
        self.applicationVersion = analyticsInfos.appInfo.version
        self.ua = analyticsInfos.userAgent.defaultUserAgent()
    }

    enum CodingKeys: String, CodingKey {
        case phoneId = "phone_id"
        case appState = "app_state"
        case libVersion = "lib_version"
        case date
        case applicationName = "application_name"
        case applicationVersion = "application_version"
        case subtype
        case ua
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(phoneId, forKey: .phoneId)
        try container.encode(appState, forKey: .appState)
        try container.encode(libVersion, forKey: .libVersion)
        try container.encode(date, forKey: .date)
        try container.encode(applicationName, forKey: .applicationName)
        try container.encode(applicationVersion, forKey: .applicationVersion)
        try container.encode(subtype, forKey: .subtype)
        try container.encode(ua, forKey: .ua)
    }

}

class Log: Encodable {
    let t = "app_mobile"
    var data: LogDataStruct

    init(data: LogDataStruct){
        self.data = data
    }
}


