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
protocol UserInfoManagerProtocol: AppStateDelegate, ResetDelegate, PredictionStoreListener {
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

    func setLocOptin( optin: LocationOptin)
    func getLocOptin() -> LocationOptin
    func registerListener(listener: UserInfoListener)
    func getUserInfo() -> UserInfo
    func resetOptinsAndCustomId(optin:Optin, customId:String)

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
  //  private var predictions: [Prediction]?
    private var predictions: [TagPrediction]?
    private var zonesPredictions: [ZonePrediction]?
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

        return herowDataHolder.getIDFA()
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


    func setLocOptin(optin: LocationOptin) {
        if getLocOptin().status != optin.status || getLocOptin().precision != optin.precision {
            self.herowDataHolder.setLocOptin(optin: optin)
            herowDataHolder.saveUserInfoWaitingForUpdate(true)
            synchronize()
        }
    }

    func getLocOptin() -> LocationOptin {
        return self.herowDataHolder.getLocOptin()
    }

    func resetOptinsAndCustomId(optin:Optin, customId:String) {
        self.herowDataHolder.setOptin(optin:optin)
        self.customId = customId
        herowDataHolder.setCustomId(customId)
        synchronize()

    }

    init( herowDataStorage: HerowDataStorageProtocol) {
        self.herowDataHolder = herowDataStorage
        if  let herowId = getHerowId() {
            GlobalLogger.shared.registerHerowId(herowId: herowId)
        }
        self.predictions = self.herowDataHolder.getLastTagPredictions()
        self.zonesPredictions = self.herowDataHolder.getLastZonesPredictions()
    }

    func registerListener(listener: UserInfoListener) {
        self.userInfoListener = listener
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
        self.userInfoListener?.onUserInfoUpdate(userInfo:  getUserInfo())
    }

    func getUserInfo() -> UserInfo {
        setLang( Locale.current.languageCode ?? "en")
        let optin = getOptin()
        let localisation = getLocOptin()
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
                                optins:[optin],
                                location: localisation,
                                predictions: self.predictions,
                                zonesPredictions: self.zonesPredictions
                                
        )

        return userInfo
    }

    func didPredict(predictions: [Prediction]) {
        self.herowDataHolder.savePredictions(predictions)
      //  self.predictions = predictions
    }

    func didZonePredict(predictions: [ZonePrediction]) {
        self.herowDataHolder.saveZonesPredictions(predictions)
        self.zonesPredictions = predictions
    }

    func didPredictionsForTags(predictions: [TagPrediction]) {
        self.herowDataHolder.saveTagsPredictions(predictions)
        self.predictions = predictions
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
        self.predictions = nil
    }

}
