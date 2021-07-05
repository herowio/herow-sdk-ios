//
//  AnalyticsManager.swift
//  herow-sdk-ios
//
//  Created by Damien on 01/02/2021.
//

import Foundation
import CoreLocation
import Foundation
import UserNotifications
import UIKit
protocol AnalyticsManagerProtocol:   EventListener, DetectionEngineListener, ClickAndConnectListener, AppStateDelegate,NotificationCreationListener, UNUserNotificationCenterDelegate{
    func createlogContex(_ location: CLLocation)
    func createlogEvent( event: Event,  info: ZoneInfo)
}
class AnalyticsManager: NSObject, AnalyticsManagerProtocol {

    private var dataStorage: HerowDataStorageProtocol?
    private var  apiManager: APIManagerProtocol
    private var cacheManager: CacheManagerProtocol
    private var onClickAndCollect = false
    private var backgroundTaskContext = UIBackgroundTaskIdentifier.invalid
    private var backgroundTaskEvent = UIBackgroundTaskIdentifier.invalid
    private var appState: String = "bg"
    init(apiManager: APIManagerProtocol, cacheManager:  CacheManagerProtocol, dataStorage: HerowDataStorageProtocol?) {
        self.apiManager = apiManager
        self.cacheManager =  cacheManager
        self.dataStorage = dataStorage
        super.init()
        NotificationDelegateDispatcher.instance.registerDelegate(self)
        NotificationDelegateDispatcher.instance.registerCreationListener(listener: self)
    }

    func didReceivedEvent(_ event: Event, infos: [ZoneInfo]) {
        for info in infos {
            if event != .GEOFENCE_NOTIFICATION_ZONE_ENTER {
             createlogEvent(event: event, info: info)
            }
        }
    }

    func onLocationUpdate(_ location: CLLocation, from: UpdateType) {
        createlogContex(location)

    }

    func createlogContex(_ location: CLLocation)  {
        if  self.backgroundTaskContext == .invalid {
            self.backgroundTaskContext = UIApplication.shared.beginBackgroundTask (
                withName: "herow.io.AnalyticsManager.backgroundTaskContextID)"  ,
                expirationHandler: {
                    if self.backgroundTaskContext != .invalid {
                        UIApplication.shared.endBackgroundTask(  self.backgroundTaskContext)
                        GlobalLogger.shared.info("AnalyticsManager ends context backgroundTask with identifier : \(   self.backgroundTaskContext)")
                        self.backgroundTaskContext = .invalid
                    }


                })
        }
        GlobalLogger.shared.info("AnalyticsManager starts context backgroundTask with identifier : \(   self.backgroundTaskContext)")
        GlobalLogger.shared.debug("AnalyticsManager - createlogContex: \(location.coordinate.latitude) \(location.coordinate.longitude)")
        let logContext = LogDataContext(appState: appState, location: location, cacheManager: cacheManager, dataStorage:  self.dataStorage, clickAndCollect: onClickAndCollect )
        if let data = logContext.getData() {
            apiManager.pushLog(data) {
                if self.backgroundTaskContext != .invalid {
                    UIApplication.shared.endBackgroundTask(  self.backgroundTaskContext)
                    GlobalLogger.shared.info("AnalyticsManager ends context backgroundTask with identifier : \(   self.backgroundTaskContext)")
                    self.backgroundTaskContext = .invalid
                }
            }
        } else {
            if self.backgroundTaskContext != .invalid {
                UIApplication.shared.endBackgroundTask(  self.backgroundTaskContext)
                GlobalLogger.shared.info("AnalyticsManager ends context backgroundTask with identifier : \(   self.backgroundTaskContext)")
                self.backgroundTaskContext = .invalid
            }
        }
    }

    func createlogEvent( event: Event,  info: ZoneInfo)  {
        if  self.backgroundTaskEvent == .invalid {
        self.backgroundTaskEvent = UIApplication.shared.beginBackgroundTask(
        withName: "herow.io.AnalyticsManager.backgroundTaskEventID"  ,
              expirationHandler: {

                if self.backgroundTaskEvent != .invalid {
                    UIApplication.shared.endBackgroundTask(  self.backgroundTaskEvent)
                    GlobalLogger.shared.info("AnalyticsManager ends Event  backgroundTask with identifier : \(   self.backgroundTaskEvent)")
                    self.backgroundTaskEvent = .invalid
                }

            })
        }
        GlobalLogger.shared.info("AnalyticsManager starts Event backgroundTask with identifier : \(   self.backgroundTaskContext)")
        GlobalLogger.shared.debug("AnalyticsManager - createlogEvent event: \(event) zoneInfo: \(info.hash)")
        let logEvent = LogDataEvent(appState: appState, event: event, infos: info, cacheManager: cacheManager, dataStorage:  self.dataStorage)
        if let data = logEvent.getData() {
            apiManager.pushLog(data) {

                if self.backgroundTaskEvent != .invalid {
                    UIApplication.shared.endBackgroundTask(  self.backgroundTaskEvent)
                    GlobalLogger.shared.info("AnalyticsManager ends Event  backgroundTask with identifier : \(   self.backgroundTaskEvent)")
                    self.backgroundTaskEvent = .invalid
                }
            }
        } else {
            if self.backgroundTaskEvent != .invalid {
                UIApplication.shared.endBackgroundTask(  self.backgroundTaskEvent)
                GlobalLogger.shared.info("AnalyticsManager ends Event  backgroundTask with identifier : \(   self.backgroundTaskEvent)")
                self.backgroundTaskEvent = .invalid
            }
        }

    }

    func didStopClickAndConnect() {
        
        onClickAndCollect = false
    }

    func didStartClickAndConnect() {
        onClickAndCollect =  true
    }

    func onAppInForeground() {
        appState = "fg"
    }

    func onAppInBackground() {
        GlobalLogger.shared.debug("appStateDetector - inBackground \(self)")
        appState = "bg"
    }

    func didCreateNotificationForCampaign(_ campaign: Campaign, zoneID: String, zoneInfo: ZoneInfo) {
        GlobalLogger.shared.debug("AnalyticsManager - create Notification Log : \(campaign.getName())")
        let log = LogDataNotification(appState: appState, campaignId: campaign.getId(), cacheManager: cacheManager, dataStorage: dataStorage, subType: .GEOFENCE_ZONE_NOTIFICATION, zoneID: zoneID, zoneInfo: zoneInfo)
        if let data = log.getData() {
           apiManager.pushLog(data) {}
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let id = response.notification.request.identifier
        let zID = response.notification.request.content.userInfo["zoneID"]
        let camp = cacheManager.getCampaigns().first {
            $0.getId() == id
        }
        guard let campaign = camp, let zoneID = zID as? String else {
            return
        }
        GlobalLogger.shared.debug("AnalyticsManager - redirect Notification Log : \(campaign.getName())")

        let log = LogDataNotification(appState: appState, campaignId: campaign.getId(), cacheManager: cacheManager, dataStorage: dataStorage, subType: .REDIRECT, zoneID: zoneID, zoneInfo: nil)
        if let data = log.getData() {
           apiManager.pushLog(data) {}
        }

    }

}
