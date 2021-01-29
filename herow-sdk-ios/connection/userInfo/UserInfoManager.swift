//
//  UserInfoManager.swift
//  herow-sdk-ios
//
//  Created by Damien on 20/01/2021.
//

import Foundation
import AppTrackingTransparency
import AdSupport

protocol UserInfoManagerProtocol: AppStateDelegate {
    func getCustomId() -> String?
    func setCustomId( _ customId: String)
    func getIDFV() -> String?
    func setIDFV( _ id: String)
    func getIDFA() -> String?
    func setIDFA( _ id: String)
    func getHerowId() -> String?
    func setHerowId( _ id: String)
    func getLang() -> String?
    func setLang( _ lang: String)
    func getOffset() -> String?
    func setOffset( _ offset: String)
    func getLocationStatus() -> String?
    func setLocationStatus( _ status: String)
    func getAccuracyStatus() -> String?
    func setAccuracyStatus( _ status: String)
    func getNotificationStatus() -> String?
    func setNotificationStatus( _ status: String)

}
class UserInfoManager: UserInfoManagerProtocol {
    private var customId : String?
    private var idfv: String?
    private var idfa: String?
    private var herowId: String?
    private var lang: String?
    private var offset: String?
    private var locationStatus: String?
    private var accuracyStatus: String?
    private var notificationStatus: String?

    var apiManager: APIManagerProtocol
    let herowDataHolder: HerowDataStorageProtocol

    func getCustomId() -> String? {
        return customId
    }

    func setCustomId(_ customId: String) {
        if herowDataHolder.getCustomId() != customId {
        self.customId = customId
            herowDataHolder.setCustomId(customId)
            herowDataHolder.saveUserInfoWaitingForUpdate(true)
        }
    }

    func getIDFV() -> String? {
        return idfv
    }

    func setIDFV(_ id: String) {
        if herowDataHolder.getIDFV() != id {
        self.idfv = id
            herowDataHolder.setIDFV(id)
            herowDataHolder.saveUserInfoWaitingForUpdate(true)
        }
    }

    func getIDFA() -> String? {
        var trackingEnabled = false
        if #available(iOS 14, *) {
            trackingEnabled = ATTrackingManager.trackingAuthorizationStatus == .authorized
        } else {
            trackingEnabled =  ASIdentifierManager.shared().isAdvertisingTrackingEnabled
        }
        // TODO: optins
        if trackingEnabled && true{
            let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
            setIDFA(idfa)
        }

        return nil
    }

    func setIDFA(_ id: String) {
        if herowDataHolder.getIDFA() != id {
        self.idfa = id
            herowDataHolder.setIDFA(id)
            herowDataHolder.saveUserInfoWaitingForUpdate(true)
        }
    }

    func getHerowId() -> String? {

        return  herowDataHolder.getUserInfo()?.herowId
    }

    func setHerowId(_ id: String) {
        if id !=  herowDataHolder.getUserInfo()?.herowId {
            herowDataHolder.setHerowId(id)
            herowDataHolder.saveUserInfoWaitingForUpdate(true)
        }
    }

    func getLang() -> String? {
        return lang
    }

    func setLang(_ lang: String) {
        if herowDataHolder.getLang() != lang {
        self.lang = lang
            herowDataHolder.setLang(lang)
            herowDataHolder.saveUserInfoWaitingForUpdate(true)
        }
    }

    func getOffset() -> String? {
        return offset
    }

    func setOffset(_ offset: String) {
        if herowDataHolder.getOffset() != offset {
        self.offset = offset
            herowDataHolder.setOffset(offset)
            herowDataHolder.saveUserInfoWaitingForUpdate(true)
        }
    }

    func getLocationStatus() -> String? {
        return locationStatus
    }

    func setLocationStatus(_ status: String) {


    }

    func getAccuracyStatus() -> String? {
        return accuracyStatus
    }

    func setAccuracyStatus(_ status: String) {

    }

    func getNotificationStatus() -> String? {
        return notificationStatus
    }

    func setNotificationStatus(_ status: String) {

    }

    init(apiManager: APIManagerProtocol, herowDataStorage: HerowDataStorageProtocol) {
        self.apiManager = apiManager
        self.herowDataHolder = herowDataStorage
    }

    func onAppInForeground() {
        synchronize()
    }

    func onAppInBackground() {
        synchronize()
    }

    func synchronize() {
        let optin = Optin(type:"USER_DATA",value: true)
        let idfa = getIDFA()
        let idfaStatus = idfa != nil
        let herowId = getHerowId()
        setCustomId("toto")
        let userInfo = UserInfo(adId:idfa, adStatus:idfaStatus, herowId: herowId, customId:getCustomId(),lang: "eng",offset:3600,optins:[optin])
        self.apiManager.currentUserInfo = userInfo
        apiManager.getUserInfoIfNeeded(completion: nil)
    }

}
