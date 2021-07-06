//
//  HerowInitializer.swift
//  herow-sdk-ios
//
//  Created by Damien on 14/01/2021.
//

import Foundation
import CoreLocation
import UIKit

@objc public class HerowInitializer: NSObject, ResetDelegate {

    @objc public static let instance = HerowInitializer()
    private var appStateDetector = AppStateDetector()
    private var apiManager: APIManager
    private var herowDataHolder: HerowDataStorageProtocol
    private var dataHolder: DataHolder
    private var connectionInfo : ConnectionInfoProtocol
    private var userInfoManager: UserInfoManagerProtocol
    private var permissionsManager: PermissionsManagerProtocol
    private let cacheManager: CacheManagerProtocol
    private var liveMomentStore: LiveMomentStoreProtocol?
    internal let geofenceManager: GeofenceManager
    private var detectionEngine: DetectionEngine
    private let zoneProvider: ZoneProvider
    private let eventDispatcher: EventDispatcher
    private let analyticsManager: AnalyticsManagerProtocol
    private let fuseManager: FuseManager
    private var notificationManager: NotificationManager
    internal  init(locationManager: LocationManager = CLLocationManager(),notificationCenter: NotificationCenterProtocol =  UNUserNotificationCenter.current()) {
        eventDispatcher = EventDispatcher()
        dataHolder = DataHolderUserDefaults(suiteName: "HerowInitializer")
        herowDataHolder = HerowDataStorage(dataHolder: dataHolder)
        connectionInfo = ConnectionInfo()
        let db =  CoreDataManager<HerowZone, HerowAccess, HerowPoi, HerowCampaign, HerowNotification, HerowCapping, HerowQuadTreeNode, HerowQuadTreeLocation>()
        cacheManager = CacheManager(db: db)
        liveMomentStore = LiveMomentStore(db: db, storage: herowDataHolder)
        userInfoManager = UserInfoManager(herowDataStorage: herowDataHolder)
        apiManager = APIManager(connectInfo: connectionInfo, herowDataStorage: herowDataHolder, cacheManager: cacheManager, userInfoManager: userInfoManager)
        userInfoManager.registerListener(listener: apiManager)
        permissionsManager = PermissionsManager(userInfoManager: userInfoManager)
        appStateDetector.registerAppStateDelegate(appStateDelegate: userInfoManager)
        detectionEngine = DetectionEngine(locationManager)
        fuseManager = FuseManager(dataHolder: dataHolder, timeProvider: TimeProviderAbsolute())
        apiManager.registerConfigListener(listener: detectionEngine)
        geofenceManager = GeofenceManager(locationManager: detectionEngine, cacheManager: cacheManager, fuseManager: fuseManager)
        appStateDetector.registerAppStateDelegate(appStateDelegate: geofenceManager)
        cacheManager.registerCacheListener(listener: geofenceManager)
        detectionEngine.registerDetectionListener(listener: fuseManager)
        detectionEngine.registerDetectionListener(listener: geofenceManager)
        if let liveMomentStore = liveMomentStore {
            detectionEngine.registerDetectionListener(listener: liveMomentStore)
            appStateDetector.registerAppStateDelegate(appStateDelegate: liveMomentStore)
            cacheManager.registerCacheListener(listener: liveMomentStore)
        }

        zoneProvider = ZoneProvider(cacheManager: cacheManager, eventDisPatcher: eventDispatcher)
        cacheManager.registerCacheListener(listener: zoneProvider)
        detectionEngine.registerDetectionListener(listener: zoneProvider)
        analyticsManager = AnalyticsManager(apiManager: apiManager, cacheManager: cacheManager, dataStorage: herowDataHolder)

        appStateDetector.registerAppStateDelegate(appStateDelegate: analyticsManager)
        appStateDetector.registerAppStateDelegate(appStateDelegate: detectionEngine)
       
        detectionEngine.registerDetectionListener(listener: analyticsManager)
        detectionEngine.registerClickAndCollectListener(listener: analyticsManager)
     
        notificationManager = NotificationManager(cacheManager: cacheManager, notificationCenter:  notificationCenter, herowDataStorage: herowDataHolder)
     
       
        super.init()

        registerEventListener(listener: analyticsManager)
        detectionEngine.registerDetectionListener(listener: apiManager)
        registerEventListener(listener: notificationManager)
    }



    @objc public func configPlatform(_ platform: HerowPlatform) -> HerowInitializer {
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


    @objc public func reset(completion: @escaping ()->()) {

        self.apiManager.reset()
        self.herowDataHolder.reset()
        self.userInfoManager.reset()
        self.cacheManager.reset(completion: completion)
    }

    @objc public func reset(platform: HerowPlatform, sdkUser: String, sdkKey: String,customID: String, completion: @escaping ((String)->())) {
        let optinState = self.userInfoManager.getOptin()
        self.reset {
            self.configPlatform(platform) .configApp(identifier: sdkUser, sdkKey: sdkKey).synchronize()
            self.setCustomId(customId: customID)
            completion(customID)

            self.userInfoManager.setOptin(optin: optinState)
        }
    }
    //MARK: EVENTLISTENERS MANAGEMENT
    @objc public func registerEventListener(listener: EventListener) {
       eventDispatcher.registerListener(listener)
   }
    //MARK: CLICKANDCOLLECT MANAGEMENT
    @objc public func isOnClickAndCollect() -> Bool {
        return detectionEngine.getIsOnClickAndCollect()
    }


    @objc public func launchClickAndCollect() {
        self.detectionEngine.setIsOnClickAndCollect(true)
    }

    func getDetectionEngine() -> DetectionEngine {
        return self.detectionEngine
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

    //MARK:DETECTIONENGINELISTENERS  MANAGEMENT
    @objc public func registerDetectionListener(listener: DetectionEngineListener) {
        detectionEngine.registerDetectionListener(listener:listener)
    }

    @objc public func unregisterDetectionListener(listener: DetectionEngineListener) {
        detectionEngine.unregisterDetectionListener(listener: listener)
    }

    //MARK: FUSEMANAGERLISTENERS  MANAGEMENT
    @objc public func  registerFuseManagerListener(listener: FuseManagerListener) {
        fuseManager.registerFuseManagerListener(listener:listener)
    }

    @objc public func unregisterFuseManagerListener(listener: FuseManagerListener) {
        fuseManager.unregisterFuseManagerListener(listener: listener)
    }

    //MARK: CACHELISTENERS  MANAGEMENT
    @objc public func  registerCacheListener(listener: CacheListener) {
        cacheManager.registerCacheListener(listener: listener)
    }

    @objc public func unregisterCacheListener(listener: CacheListener) {
        cacheManager.unregisterCacheListener(listener: listener)
    }

    //MARK: GEOFENCEMANAGERLISTENERS  MANAGEMENT
    @objc public func  registerGeofenceManagerListener(listener: GeofenceManagerListener) {
        geofenceManager.registerGeofenceManagerListener(listener: listener)
    }

    @objc public func unregisterGeofenceManagerListenerr(listener: GeofenceManagerListener) {
        geofenceManager.unregisterGeofenceManagerListener(listener: listener)
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

    @objc public func removeCustomId() {
        self.userInfoManager.removeCustomId()
    }

    //MARK: DATABASE MANAGEMENT
    @objc public func getHerowZoneForId(id: String) -> HerowZone? {
        guard let zone =  cacheManager.getZones(ids: [id]).first else { return nil }
        return HerowZone(zone: zone)
    }

    @objc public func getHerowZones(completion:@escaping  ([HerowZone])->()) {
        DispatchQueue.global(qos: .background).async {
            let zones =  self.cacheManager.getZones().map {
                HerowZone(zone: $0)
            }
            DispatchQueue.main.async {
                completion(zones)
            }
        }
    }

    public func getClusters() -> [NodeDescription]? {
        return  liveMomentStore?.getClusters()?.getReccursiveRects(nil)
    }

    public func registerLiveMomentStoreListener(listener: LiveMomentStoreListener) {
        liveMomentStore?.registerLiveMomentStoreListener(listener)
    }

    public func registerAppStateListener(listener: AppStateDelegate) {
        appStateDetector.registerAppStateDelegate(appStateDelegate: listener)
    }
    public func getHome() -> QuadTreeNode? {
        return  liveMomentStore?.getHome()
    }

    public func getWork() -> QuadTreeNode? {
        return  liveMomentStore?.getWork()
    }

    public func getSchool() -> QuadTreeNode? {
        return  liveMomentStore?.getSchool()
    }

    public func getShoppings() -> [QuadTreeNode]? {
        return  liveMomentStore?.getShopping()
    }

    public func getPOIs() -> [Poi] {
        return cacheManager.getPois()
    }

    //MARK: UTILS
    @objc public func dispatchFakeLocation(_ location: CLLocation) {
        detectionEngine.dispatchFakeLocation(location)
    }

    @objc public func notificationsOnExactZoneEntry(_ value: Bool) {
        notificationManager.notificationsOnExactZoneEntry(value)
    }

    @objc public func getVersion() -> String {
        return AnalyticsInfo().libInfo.version
    }

}

extension UNUserNotificationCenter : NotificationCenterProtocol {

}
