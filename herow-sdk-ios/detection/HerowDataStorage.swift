//
//  HerowDataStorage.swift
//  herow-sdk-ios
//
//  Created by Damien on 20/01/2021.
//

import Foundation



public class HerowDataStorage: HerowDataStorageProtocol {




    private var userInfo: APIUserInfo?
    private var token: APIToken?
    private var config: APIConfig?
    private var lastGeoHash: String?
    let dataHolder: DataHolder

    init(dataHolder: DataHolder) {
        self.dataHolder = dataHolder
    }
    // MARK: Connection methods
    public func saveToken(_ token: APIToken) {
        var aToken = token
        aToken.expirationDate = Date().addingTimeInterval(TimeInterval(aToken.expiresIn))
        self.token = aToken
        guard let data = aToken.encode() else {
            return
        }
        dataHolder.putData(key: HerowConstants.tokenKey, value: data)
        dataHolder.apply()
    }

    public func getToken() -> APIToken? {

        if let token = self.token {
            return token
        }
        guard let data = dataHolder.getData(key: HerowConstants.tokenKey) else {
            return nil
        }
        guard let token = APIToken.decode(data: data)  else {
            return nil
        }
        return token
    }
    
    public func saveUserInfo( _ userInfo: APIUserInfo) {
        guard let data = userInfo.encode() else {
            return
        }
        self.userInfo = userInfo
        dataHolder.putData(key: HerowConstants.userInfoKey, value: data)
        dataHolder.apply()
    }

    public func getUserInfo() -> APIUserInfo? {

        if let userInfo = self.userInfo {
            return userInfo
        }
        guard let data = dataHolder.getData(key: HerowConstants.userInfoKey) else {
            return nil
        }
        guard let userInfo = APIUserInfo.decode(data: data)  else {
            return nil
        }
        return userInfo
    }

    public func tokenIsExpired() -> Bool {
        guard let token = getToken(), let date = token.expirationDate else {
            return true
        }
        let shouldRefresh = date < Date()
        if shouldRefresh {
            self.token = nil
        }
        return shouldRefresh
    }

    public func getConfig() -> APIConfig? {

        if let config = self.config {
            return self.config
        }
        guard let data = dataHolder.getData(key: HerowConstants.configKey) else {
            return nil
        }
        guard let config = APIConfig.decode(data: data)  else {
            return nil
        }
        return config
    }

    private func getLastConfigDate() -> Date? {

        return dataHolder.getDate(key: HerowConstants.configDateKey)
    }

    public func saveUserInfoWaitingForUpdate(_ waitForUpdate: Bool) {
       dataHolder.putBoolean(key: HerowConstants.userInfoStatusKey, value: waitForUpdate)
       dataHolder.apply()
    }

    public func userInfoWaitingForUpdate() -> Bool {
        if let _ = getUserInfo()?.herowId {
            return  dataHolder.getBoolean(key: HerowConstants.userInfoStatusKey)
        }
        return true
    }

    public func saveConfig( _ config: APIConfig) {
        guard let data = config.encode() else {
            return
        }
        self.config = config
        dataHolder.putDate(key: HerowConstants.configDateKey, value: Date())
        dataHolder.putData(key: HerowConstants.configKey, value: data)
        dataHolder.apply()
    }

    public func getLastGeoHash() -> String? {
        if let geoHash = lastGeoHash {
            return geoHash
        }
        return dataHolder.getString(key:  HerowConstants.geoHashKey)
    }

    public func setLastGeohash(_ hash: String) {
        lastGeoHash = hash
        dataHolder.putString(key: HerowConstants.geoHashKey, value: hash)
        dataHolder.apply()
    }

    public func saveLastCacheModifiedDate(_ date: Date) {
        dataHolder.putDate(key: HerowConstants.lastCacheModifiedDateKey, value: date)
        dataHolder.apply()
    }

    public func getLastCacheModifiedDate() -> Date? {
        dataHolder.getDate(key: HerowConstants.lastCacheModifiedDateKey)
    }

    public func saveLastCacheFetchDate(_ date: Date) {
        dataHolder.putDate(key: HerowConstants.lastCacheFetchDateKey, value: date)
        dataHolder.apply()
    }

    public func getLastCacheFetchDate() -> Date? {
        dataHolder.getDate(key: HerowConstants.lastCacheFetchDateKey)
    }

    public func shouldGetCache(for hash: String) -> Bool {
        guard let savedhash = getLastGeoHash(),
              let lastCacheModifiedDate = getLastCacheModifiedDate(),
              let cacheInterval = getConfig()?.cacheInterval,
              let lastFetchDate = getLastCacheFetchDate() else {
            return true
        }
        let now = Date()
        let differentHash = hash != savedhash
        let cacheIsNotUptoDate = lastFetchDate < lastCacheModifiedDate
        let shouldFetchNow =  now > lastFetchDate.addingTimeInterval(TimeInterval(cacheInterval / 1000))

        if differentHash {
            GlobalLogger.shared.debug("CACHE SHOULD BE FETCH BECAUSE OF DIFFERENT HASH")
        }
        if cacheIsNotUptoDate {
            GlobalLogger.shared.debug("CACHE SHOULD BE FETCH BECAUSE OF CACHE IS NOT UP TO DATE")
        }
        if shouldFetchNow {
            GlobalLogger.shared.debug("CACHE SHOULD BE FETCH BECAUSE OF CACHE INTERVAL IS DONE")
        }
        return differentHash ||
            cacheIsNotUptoDate ||
            shouldFetchNow
    }

    public func shouldGetConfig() -> Bool {
        if let config = getConfig(), let lastDate = getLastConfigDate() {
            let timeInterval = TimeInterval(config.configInterval) / 1000
            return lastDate.addingTimeInterval(timeInterval) < Date()
        }
        return true
    }

    // MARK: UserInfo methods

    public func getCustomId() -> String? {
       return  dataHolder.getString(key: HerowConstants.customIdKey)
    }

    public func setCustomId( _ customId: String) {
        dataHolder.putString(key: HerowConstants.customIdKey, value: customId)
        dataHolder.apply()
    }

    public func getIDFV() -> String? {
       return  dataHolder.getString(key: HerowConstants.idfvKey)
    }

    public func setIDFV( _ id: String) {
        dataHolder.putString(key: HerowConstants.idfvKey, value: id)
        dataHolder.apply()
    }

    public func getIDFA() -> String? {
       return  dataHolder.getString(key: HerowConstants.idfaKey)
    }

    public func setIDFA( _ id: String) {
        dataHolder.putString(key: HerowConstants.idfaKey, value: id)
        dataHolder.apply()
    }

    public func getHerowId() -> String? {
        return  getUserInfo()?.herowId
    }

    public func setHerowId( _ id: String) {
        dataHolder.putString(key: HerowConstants.herowIdKey, value: id)
        dataHolder.apply()
    }

    public func getLang() -> String? {
       return  dataHolder.getString(key: HerowConstants.langKey)
    }

    public func setLang( _ lang: String) {
        dataHolder.putString(key: HerowConstants.langKey, value: lang)
        dataHolder.apply()
    }

    public func getOffset() -> Int? {
       return  dataHolder.getInt(key: HerowConstants.utcOffsetKey)
    }

    public func setOffset( _ offset: Int) {
        dataHolder.putInt(key: HerowConstants.utcOffsetKey, value: offset)
        dataHolder.apply()
    }

    public func getLocationStatus() -> String? {
       return  dataHolder.getString(key: HerowConstants.locationStatusKey)
    }

    public func setLocationStatus( _ status: String) {
        dataHolder.putString(key: HerowConstants.locationStatusKey, value: status)
        dataHolder.apply()
    }

    public func getAccuracyStatus() -> String? {
       return  dataHolder.getString(key: HerowConstants.accuracyStatusKey)
    }

    public func setAccuracyStatus( _ status: String) {
        dataHolder.putString(key: HerowConstants.accuracyStatusKey, value: status)
        dataHolder.apply()
    }

    public func getNotificationStatus() -> String? {
       return  dataHolder.getString(key: HerowConstants.notificationStatusKey)
    }

    public func setNotificationStatus( _ status: String) {
        dataHolder.putString(key: HerowConstants.notificationStatusKey, value: status)
        dataHolder.apply()
    }

    public func reset() {

        dataHolder.remove(key: HerowConstants.tokenKey)
        dataHolder.remove(key: HerowConstants.configKey)
        dataHolder.remove(key: HerowConstants.userInfoKey)
        dataHolder.remove(key: HerowConstants.lastCacheModifiedDateKey)
        dataHolder.remove(key: HerowConstants.lastCacheModifiedDateKey)
        dataHolder.remove(key: HerowConstants.configDateKey)
        dataHolder.remove(key: HerowConstants.geoHashKey)
        dataHolder.apply()

    }

}
