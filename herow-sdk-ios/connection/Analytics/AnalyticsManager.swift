//
//  AnalyticsManager.swift
//  herow-sdk-ios
//
//  Created by Damien on 01/02/2021.
//

import Foundation
import CoreLocation
import Foundation


class AnalyticsManager: EventListener, DetectionEngineListener, ClickAndConnectListener,AppStateDelegate  {


    private var dataStorage: HerowDataStorageProtocol?
    private var  apiManager: APIManagerProtocol
    private var cacheManager: CacheManagerProtocol
    private var onClickAndCollect = false
    private var appState: String = "bg"
    init(apiManager: APIManagerProtocol, cacheManager:  CacheManagerProtocol, dataStorage: HerowDataStorageProtocol?) {
        self.apiManager = apiManager
        self.cacheManager =  cacheManager
        self.dataStorage = dataStorage
    }

    func didReceivedEvent(_ event: Event, infos: [ZoneInfo]) {
        for info in infos {
             createlogEvent(event: event, info: info)
        }
    }

    func onLocationUpdate(_ location: CLLocation, from: UpdateType) {
        createlogContex(location)

    }

    func createlogContex(_ location: CLLocation)  {
        GlobalLogger.shared.debug("AnalyticsManager - createlogContex: \(location.coordinate.latitude) \(location.coordinate.longitude)")
        let logContext = LogDataContext(appState: appState, location: location, cacheManager: cacheManager, dataStorage:  self.dataStorage, clickAndCollect: onClickAndCollect )
        if let data = logContext.getData() {
            apiManager.pushLog(data) {}
        }
    }

    func createlogEvent( event: Event,  info: ZoneInfo)  {
        GlobalLogger.shared.debug("AnalyticsManager - createlogEvent event: \(event) zoneInfo: \(info.hash)")
        let logEvent = LogDataEvent(appState: appState, event: event, infos: info, cacheManager: cacheManager, dataStorage:  self.dataStorage)
        if let data = logEvent.getData() {
            apiManager.pushLog(data) {}
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
        appState = "bg"
    }

}
