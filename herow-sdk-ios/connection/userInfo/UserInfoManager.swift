//
//  UserInfoManager.swift
//  herow-sdk-ios
//
//  Created by Damien on 20/01/2021.
//

import Foundation
import AppTrackingTransparency
import AdSupport


protocol UserInfoListener: class {
    func  onUserInfoUpdate(userInfo: UserInfo)
}
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
    func getOffset() -> Int?
    func setOffset( _ offset: Int)
    func getLocationStatus() -> String?
    func setLocationStatus( _ status: String)
    func getAccuracyStatus() -> String?
    func setAccuracyStatus( _ status: String)
    func getNotificationStatus() -> String?
    func setNotificationStatus( _ status: String)
    func getOptin() -> Optin
    func setOptin( optin: Optin)

}
class UserInfoManager: UserInfoManagerProtocol {


    private var customId : String?
    private var idfv: String?
    private var idfa: String?
    private var herowId: String?
    private var lang: String?
    private var offset: Int?
    private var locationStatus: String?
    private var accuracyStatus: String?
    private var notificationStatus: String?

    weak  var  userInfoListner: UserInfoListener?
    let herowDataHolder: HerowDataStorageProtocol

    func getCustomId() -> String? {
        return herowDataHolder.getCustomId()
    }

    func setCustomId(_ customId: String) {
        if herowDataHolder.getCustomId() != customId {
            self.customId = customId
            herowDataHolder.setCustomId(customId)
            herowDataHolder.saveUserInfoWaitingForUpdate(true)
            synchronize()
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
            synchronize()
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
            synchronize()
        }
    }

    func getHerowId() -> String? {

        return  herowDataHolder.getUserInfo()?.herowId
    }

    func setHerowId(_ id: String) {
        if id !=  herowDataHolder.getUserInfo()?.herowId {
            herowDataHolder.setHerowId(id)
            herowDataHolder.saveUserInfoWaitingForUpdate(true)
            synchronize()
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
            synchronize()
        }
    }

    func getOffset() -> Int? {
        return herowDataHolder.getOffset()
    }

    func setOffset(_ offset: Int) {
        if herowDataHolder.getOffset() != offset {
            self.offset = offset
            herowDataHolder.setOffset(offset)
            herowDataHolder.saveUserInfoWaitingForUpdate(true)
            synchronize()
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

    func getOptin() -> Optin {
        return self.herowDataHolder.getOptin()
    }

    func setOptin(optin: Optin) {
        if getOptin().value != optin.value {
            self.herowDataHolder.setOptin(optin: optin)
            herowDataHolder.saveUserInfoWaitingForUpdate(true)
            synchronize()
        }
    }

    init(listener: UserInfoListener, herowDataStorage: HerowDataStorageProtocol) {
        self.userInfoListner = listener
        self.herowDataHolder = herowDataStorage
    }

    func onAppInForeground() {
        if herowDataHolder.userInfoWaitingForUpdate() {
            synchronize()
        }
    }

    func onAppInBackground() {
        if herowDataHolder.userInfoWaitingForUpdate() {
            synchronize()
        }
    }

    func synchronize() {
        setLang( Locale.current.languageCode ?? "en")
        let optin = getOptin()
        let idfa: String?  = getIDFA()
        let idfaStatus = idfa != nil
        let herowId = getHerowId()
        setOffset(TimeZone.current.secondsFromGMT() * 1000)
        let customId: String? = getCustomId()
        let lang: String = getLang() ?? "en"
        let offset: Int = getOffset() ?? TimeZone.current.secondsFromGMT() * 1000
        let userInfo = UserInfo(adId: idfa,
                                adStatus: idfaStatus,
                                herowId: herowId,
                                customId: customId, lang: lang,
                                offset: offset,
                                optins:[optin])
        
        self.userInfoListner?.onUserInfoUpdate(userInfo: userInfo)
    }

}
