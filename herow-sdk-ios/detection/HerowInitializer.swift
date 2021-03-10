//
//  HerowInitializer.swift
//  herow-sdk-ios
//
//  Created by Damien on 14/01/2021.
//

import Foundation
import CoreLocation


@objc public class HerowInitializer: NSObject, ResetDelegate {

   public static let instance = HerowInitializer()
    private var appStateDetector = AppStateDetector()
    private var apiManager: APIManager
    private var herowDataHolder: HerowDataStorageProtocol
    private var dataHolder: DataHolder
    private var connectionInfo : ConnectionInfoProtocol
    private var userInfoManager: UserInfoManagerProtocol
    private var permissionsManager: PermissionsManagerProtocol
    private let cacheManager: CacheManagerProtocol

    private let geofenceManager: GeofenceManager
    private var detectionEngine: DetectionEngine
    private let zoneProvider: ZoneProvider
    private let eventDispatcher: EventDispatcher
    private let analyticsManager: AnalyticsManager
    internal  init(locationManager: LocationManager = CLLocationManager()) {

        eventDispatcher = EventDispatcher()
        dataHolder = DataHolderUserDefaults(suiteName: "HerowInitializer")
        herowDataHolder = HerowDataStorage(dataHolder: dataHolder)
        connectionInfo = ConnectionInfo()
        cacheManager = CacheManager(db: CoreDataManager<HerowZone, HerowAccess, HerowPoi, HerowCampaign, HerowInterval, HerowNotification>())
        apiManager = APIManager(connectInfo: connectionInfo, herowDataStorage: herowDataHolder, cacheManager: cacheManager)
        userInfoManager = UserInfoManager(listener: apiManager, herowDataStorage: herowDataHolder)
        permissionsManager = PermissionsManager(userInfoManager: userInfoManager)
        appStateDetector.registerAppStateDelegate(appStateDelegate: userInfoManager)
        detectionEngine = DetectionEngine(locationManager)
        geofenceManager = GeofenceManager(locationManager: detectionEngine, cacheManager: cacheManager)
        cacheManager.registerCacheListener(listener: geofenceManager)
        detectionEngine.registerDetectionListener(listener: geofenceManager)
        zoneProvider = ZoneProvider(cacheManager: cacheManager, eventDisPatcher: eventDispatcher)
        cacheManager.registerCacheListener(listener: zoneProvider)
        detectionEngine.registerDetectionListener(listener: zoneProvider)
        apiManager.registerConfigListener(listener: detectionEngine)
        analyticsManager = AnalyticsManager(apiManager: apiManager, cacheManager: cacheManager, dataStorage: herowDataHolder)
        appStateDetector.registerAppStateDelegate(appStateDelegate: analyticsManager)
        detectionEngine.registerDetectionListener(listener: analyticsManager)
        detectionEngine.registerClickAndCollectListener(listener: analyticsManager)

        super.init()
        registerEventListener(listener: analyticsManager)
        detectionEngine.registerDetectionListener(listener: apiManager)
    }



    @objc public func configPlatform(_ platform: String) -> HerowInitializer {
        connectionInfo.updatePlateform(platform)
        self.apiManager.configure(connectInfo: connectionInfo)
        return self
    }

    @objc public func configApp(identifier: String, sdkKey: String) -> HerowInitializer {
        self.apiManager.user = User(login: identifier, password: sdkKey)
        return self
    }

    @objc public func synchronize(completion:(()->())? = nil) {
        self.apiManager.getConfigIfNeeded {
            completion?()
        }
    }

    @objc public func getPermissionManager() -> PermissionsManagerProtocol {
        return permissionsManager
    }


    @objc public func reset() {
     self.herowDataHolder.reset()
     }
    //MARK: EVENTLISTENERS MANAGEMENT
    @objc public func registerEventListener(listener: EventListener) {
       eventDispatcher.registerListener(listener)
   }
    //MARK: CLICKANDCOLLECT  MANAGEMENT
    @objc public func isOnClickAndCollect() -> Bool {
        return detectionEngine.getIsOnClickAndCollect()
    }


    @objc public func launchClickAndCollect() {
        self.detectionEngine.setIsOnClickAndCollect(true)

    }

    @objc public func stopClickAndCollect() {
        self.detectionEngine.setIsOnClickAndCollect(false)
    }
    //MARK: CLICKANDCOLLECTLISTENERS  MANAGEMENT
    @objc public func registerClickAndCollectListener(listener: ClickAndConnectListener) {
        detectionEngine.registerClickAndCollectListener(listener:listener)
    }

    @objc public func unregisterClickAndCollectListener(listener: ClickAndConnectListener) {
        detectionEngine.unregisterClickAndCollectListener(listener: listener)
    }

    //MARK: USERINFO MANAGEMENT
    @objc public func getOptinValue() -> Bool {
        return userInfoManager.getOptin().value
    }

    @objc public func acceptOptin() {
        self.userInfoManager.setOptin(optin: Optin.optinDataOk)

    }

    @objc public func refuseOptin() {
        self.userInfoManager.setOptin(optin: Optin.optinDataNotOk)

    }

    @objc public func getCustomId() -> String? {
        return userInfoManager.getCustomId()
    }

    @objc public func setCustomId(customId: String) {
        self.userInfoManager.setCustomId(customId)

    }

    @objc public func getHerowZoneForId(id: String) -> HerowZone? {
        guard let zone =  cacheManager.getZones(ids: [id]).first else { return nil }
        return HerowZone(zone: zone)
    }




}
