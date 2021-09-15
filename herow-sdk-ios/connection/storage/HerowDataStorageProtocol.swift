//
//  HerowDataStorageProtocol.swift
//  herow-sdk-ios
//
//  Created by Damien on 23/01/2021.
//

import Foundation

public protocol HerowDataStorageProtocol: ResetDelegate {
    func saveToken( _ token: APIToken)
    func saveUserInfo( _ userInfo: APIUserInfo)
    func saveConfig( _ config: APIConfig)
    func getToken() -> APIToken?
    func getUserInfo() -> APIUserInfo?
    func getConfig() -> APIConfig?
    func tokenIsExpired() -> Bool
    func shouldGetConfig() -> Bool
    func saveUserInfoWaitingForUpdate( _ waitForUpdate: Bool)
    func userInfoWaitingForUpdate() -> Bool
    func getLastGeoHash() -> String?
    func setLastGeohash(_ hash: String)
    func shouldGetCache(for hash: String) -> Bool
    func saveLastCacheModifiedDate(_ date: Date)
    func getLastCacheModifiedDate() -> Date?
    func saveLastCacheFetchDate(_ date: Date)
    func getLastCacheFetchDate() -> Date?
    func removeToken()

    func removeCustomId()
    func getCustomId() -> String?
    func setCustomId( _ customId: String)
    func getIDFV() -> String?
    func setIDFV( _ id: String)
    func getIDFA() -> String?
    func setIDFA( _ id: String)
    func getHerowId() -> String?
    func getLang() -> String?
    func setLang( _ lang: String)
    func getOffset() -> Int?
    func setOffset( _ offset: Int)
    func getLocationStatus() -> String?
    func setLocationStatus( _ status: String)
    func getAccuracyStatus() -> String?
    func setAccuracyStatus( _ status: String)
    func getNotificationStatus() -> String?
    func setNotificationStatus( _ status: String)
    func getOptin() -> Optin
    func setOptin(optin: Optin)


    //LiveMoment
    func saveLiveMomentLastSaveDate(_ date: Date)
    func getLiveMomentLastSaveDate() -> Date?

}

extension HerowDataStorageProtocol {

    func useExactEntry() -> Bool {
        return UserDefaults.standard.bool(forKey: "exactEntry")
    }

    func setUseExactEntry(_ value: Bool)  {
        UserDefaults.standard.set(value, forKey: "exactEntry")
        UserDefaults.standard.synchronize()
    }
}
