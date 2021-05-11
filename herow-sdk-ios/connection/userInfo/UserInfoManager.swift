//
//  UserInfoManager.swift
//  herow-sdk-ios
//
//  Created by Damien on 20/01/2021.
//

import Foundation
import AppTrackingTransparency
import AdSupport


protocol UserInfoListener: AnyObject {
    func  onUserInfoUpdate(userInfo: UserInfo)
}
protocol UserInfoManagerProtocol: AppStateDelegate, ResetDelegate {
    func getCustomId() -> String?
    func removeCustomId()
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

    weak  var  userInfoListener: UserInfoListener?
    let herowDataHolder: HerowDataStorageProtocol


    func removeCustomId() {
        if getCustomId() != nil {
        herowDataHolder.removeCustomId()
        herowDataHolder.saveUserInfoWaitingForUpdate(true)
        synchronize()
        }
    }
    
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
        self.userInfoListener = listener
        self.herowDataHolder = herowDataStorage
        if  let herowId = getHerowId() {
            GlobalLogger.shared.registerHerowId(herowId: herowId)
        }

    }

    func onAppInForeground() {
      /*  if herowDataHolder.userInfoWaitingForUpdate() {
            synchronize()
        }*/
    }

    func onAppInBackground() {
      /*  if herowDataHolder.userInfoWaitingForUpdate() {
            synchronize()
        }*/
    }

    func synchronize() {
        setLang( Locale.current.languageCode ?? "en")
        let optin = getOptin()
        let idfa: String?  = getIDFA()
        let idfaStatus = idfa != nil
        if  let herowId = getHerowId() {
            GlobalLogger.shared.registerHerowId(herowId: herowId)
        }
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
        
        self.userInfoListener?.onUserInfoUpdate(userInfo: userInfo)
    }

    func reset(completion: @escaping ()->()) {
        removeCustomId()
        self.customId = nil
        self.idfv = nil
        self.idfa = nil
        self.herowId = nil
        self.lang = nil
        self.offset = nil
        self.locationStatus = nil
        self.accuracyStatus = nil
        self.notificationStatus = nil
        self.herowDataHolder.reset(completion:completion)
    }

}
