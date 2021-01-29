//
//  HerowInitializer.swift
//  herow-sdk-ios
//
//  Created by Damien on 14/01/2021.
//

import Foundation
import CoreLocation
@objc public class HerowInitializer: NSObject {

   public static let instance = HerowInitializer()
    private var appStateDetector = AppStateDetector()
    private var apiManager: APIManager
    private var herowDataHolder: HerowDataStorageProtocol
    private var dataHolder: DataHolder
    private var connectionInfo : ConnectionInfo
    private var userInfoManager: UserInfoManagerProtocol
    private var permissionsManager: PermissionsManagerProtocol
    private let cacheManager: CacheManagerProtocol

    private let geofenceManager: GeofenceManager
    private let detectionEngine: DetectionEngine
    private let zoneProvider: ZoneProvider
   // private let eventDispatcher: EventDispatcher
    private override init() {

       // eventDispatcher = EventDispatcher()
        dataHolder = DataHolderUserDefaults(suiteName: "HerowInitializer")
        herowDataHolder = HerowDataStorage(dataHolder: dataHolder)
        connectionInfo = ConnectionInfo()
        cacheManager = CacheManager(db: CoreDataManager<HerowZone, HerowAccess, HerowPoi, HerowCampaign, HerowInterval, HerowNotification>())
        apiManager = APIManager(connectInfo: connectionInfo, herowDataStorage: herowDataHolder, cacheManager: cacheManager)
        userInfoManager = UserInfoManager(apiManager: apiManager, herowDataStorage: herowDataHolder)
        permissionsManager = PermissionsManager(userInfoManager: userInfoManager)
        appStateDetector.registerAppStateDelegate(appStateDelegate: userInfoManager)
        detectionEngine = DetectionEngine(CLLocationManager())
        geofenceManager = GeofenceManager(locationManager: detectionEngine, cacheManager: cacheManager)
        cacheManager.registerCacheListener(listener: geofenceManager)
        detectionEngine.registerDetectionListener(listener: geofenceManager)
        zoneProvider = ZoneProvider(cacheManager: cacheManager)
        cacheManager.registerCacheListener(listener: zoneProvider)
        detectionEngine.registerDetectionListener(listener: zoneProvider)
        apiManager.registerConfigListener(listener: detectionEngine)
        super.init()
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

    @objc public func synchronize() {
        self.apiManager.getConfigIfNeeded()
    }

    @objc public func getPermissionManager() -> PermissionsManagerProtocol {
        return permissionsManager
    }



}
