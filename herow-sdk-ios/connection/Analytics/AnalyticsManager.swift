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

protocol AnalyticsManagerProtocol:   EventListener, DetectionEngineListener, ClickAndConnectListener, AppStateDelegate,NotificationCreationListener, UNUserNotificationCenterDelegate, LiveMomentStoreListener{
    func createlogContex(_ location: CLLocation)
    func createlogEvent( event: Event,  info: ZoneInfo)
    func registerListener(listener: AnalyticsManagerListener)
    func unregisterListener(listener: AnalyticsManagerListener)
}

public protocol AnalyticsManagerListener: AnyObject {
    func didOpenNotificationForCampaign(_ campaign: Campaign, zoneID: String)
    func didCreateNotificationForCampaign(_ campaign: Campaign, zoneID: String, zoneInfo: ZoneInfo)
}

class AnalyticsManager: NSObject, AnalyticsManagerProtocol {



    private var dataStorage: HerowDataStorageProtocol?
    private var  apiManager: APIManagerProtocol
    private var cacheManager: CacheManagerProtocol
    private var onClickAndCollect = false
    private var backgroundTaskContext = UIBackgroundTaskIdentifier.invalid
    private var backgroundTaskEvent = UIBackgroundTaskIdentifier.invalid
    private var appState: String = "bg"
    private var  listeners = [WeakContainer<AnalyticsManagerListener>]()
    private var home : QuadTreeNode?
    private var work : QuadTreeNode?
    private var school : QuadTreeNode?
    private var shoppings : [QuadTreeNode]?
    private let allowedEvents = [Event.GEOFENCE_ENTER, Event.GEOFENCE_EXIT, Event.GEOFENCE_VISIT]

    init(apiManager: APIManagerProtocol, cacheManager:  CacheManagerProtocol, dataStorage: HerowDataStorageProtocol?) {
        self.apiManager = apiManager
        self.cacheManager =  cacheManager
        self.dataStorage = dataStorage
        super.init()
        NotificationDelegateDispatcher.instance.registerDelegate(self)
        NotificationDelegateDispatcher.instance.registerCreationListener(listener: self)
    }

    deinit {
        for listener in listeners {
            self.unregisterListener(listener: listener.get()!)
        }
    }

    func didReceivedEvent(_ event: Event, infos: [ZoneInfo]) {
        for info in infos {
            if  allowedEvents.contains(event) {
                GlobalLogger.shared.info("AnalyticsManager - send event: \(event.toString())")
             createlogEvent(event: event, info: info)
            }
        }
    }

    func onLocationUpdate(_ location: CLLocation, from: UpdateType) {

        createlogContex(location)

    }

    func registerListener(listener: AnalyticsManagerListener) {
      let first = listeners.first {
          ($0.get() === listener) == true
      }
      if first == nil {
          listeners.append(WeakContainer<AnalyticsManagerListener>(value: listener))
      }
  }

    func unregisterListener(listener: AnalyticsManagerListener) {
      listeners = listeners.filter {
          ($0.get() === listener) == false
      }
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

        let homeConfidence = computeHomeConfidence(location)
        let workConfidence = computeWorkConfidence(location)
        let schoolConfidence = computeSchoolConfidence(location)
        let shopConfidence = computeShoppingConfidence(location)
        let moments = Moments(home: homeConfidence, office: workConfidence, shopping: shopConfidence, other: schoolConfidence)
        GlobalLogger.shared.info("AnalyticsManager compute confidence : Home: \(homeConfidence) Work: \(workConfidence) School: \(schoolConfidence) Shop: \(shopConfidence)")
        //TODO:  insert confidence into log
        let logContext = LogDataContext(appState: appState, location: location, cacheManager: cacheManager, dataStorage:  self.dataStorage, clickAndCollect: onClickAndCollect,moments: moments )
        if let data = logContext.getData() {
            apiManager.pushLog(data, SubType.CONTEXT.rawValue) {
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
            apiManager.pushLog(data, event.toString()) {

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
            apiManager.pushLog(data, SubType.GEOFENCE_ZONE_NOTIFICATION.rawValue) {}
        }

        for listener in listeners {
            listener.get()?.didCreateNotificationForCampaign(campaign, zoneID: zoneID, zoneInfo: zoneInfo)
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        guard let id = response.notification.request.identifier.components(separatedBy: "_").first else {
            return
        }
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
            apiManager.pushLog(data, SubType.REDIRECT.rawValue) {}
        }

        for listener in listeners {
            listener.get()?.didOpenNotificationForCampaign(campaign, zoneID: zoneID)
        }

    }


    func liveMomentStoreStartComputing() {
        //di nothing
    }

    func didCompute(rects: [NodeDescription]?, home: QuadTreeNode?, work: QuadTreeNode?, school: QuadTreeNode?, shoppings: [QuadTreeNode]?, others: [QuadTreeNode]?, neighbours: [QuadTreeNode]?, periods: [PeriodProtocol]) {
        self.home = home
        self.work = work
        self.school = school
        self.shoppings = shoppings
    }

    func getFirstLiveMoments(home: QuadTreeNode?, work: QuadTreeNode?, school: QuadTreeNode?, shoppings: [QuadTreeNode]?) {
        self.home = home
        self.work = work
        self.school = school
        self.shoppings = shoppings
    }

    func didChangeNode(node: QuadTreeNode) {
        // do nothing
    }


    private func confidenceForNode(_ node: QuadTreeNode, location: CLLocation) -> Double {
        let center = node.getRect().circle().center
        let centerLoc = CLLocation(latitude: center.latitude, longitude: center.longitude)
        let radius = node.getRect().circle().radius
        return LocationUtils.computeConfidence(centerLocation: centerLoc, location: location, radius: radius)
    }
    private func computeHomeConfidence(_ location : CLLocation) -> Double {
        guard let node = self.home else {
            return 0
        }
        return confidenceForNode(node, location: location)
    }

    private func computeWorkConfidence(_ location : CLLocation) -> Double {
        guard let node = self.work else {
            return 0
        }
        return confidenceForNode(node, location: location)
    }

    private func computeSchoolConfidence(_ location : CLLocation) -> Double {
        guard let node = self.school else {
            return 0
        }
        return confidenceForNode(node, location: location)
    }

    private func computeShoppingConfidence(_ location : CLLocation) -> Double {
        guard let shoppings = self.shoppings else {
            return 0
        }
        var result = 0.0
        for shop in shoppings {
            result = max(result,confidenceForNode(shop, location: location))
        }
        return result
    }

}
