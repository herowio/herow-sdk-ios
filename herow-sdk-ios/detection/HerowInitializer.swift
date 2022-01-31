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


    public  static var coreDataListeners = [CoreDataManagerCrashListener]()
    @objc public static let instance = HerowInitializer()
    private var appStateDetector = AppStateDetector()
    private var apiManager: APIManager
    private var herowDataHolder: HerowDataStorageProtocol
    private var dataHolder: DataHolderUserDefaults
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
    private var predictionStore: PredictionStoreProtocol
    private var redirectionCatcher: RedirectionsCatcher
    private var db:  CoreDataManager<HerowZone, HerowAccess, HerowPoi, HerowCampaign, HerowNotification, HerowCapping, HerowQuadTreeNode, HerowQuadTreeLocation, HerowPeriod>

    internal  init(locationManager: LocationManager = CLLocationManager(),notificationCenter: NotificationCenterProtocol? = NotificationDelegateHolder.shared.useNotificationCenter ? UNUserNotificationCenter.current() : nil) {
        eventDispatcher = EventDispatcher()
        db =  CoreDataManager<HerowZone, HerowAccess, HerowPoi, HerowCampaign, HerowNotification, HerowCapping, HerowQuadTreeNode, HerowQuadTreeLocation, HerowPeriod>()
        for listener in HerowInitializer.coreDataListeners {
            db.registerCrashListener(listener)
        }


        dataHolder = DataHolderUserDefaults(suiteName: "HerowInitializer")
        herowDataHolder = HerowDataStorage(dataHolder: dataHolder)
        connectionInfo = ConnectionInfo()
        cacheManager = CacheManager(db: db)
        liveMomentStore = LiveMomentStore(db: db, storage: herowDataHolder)
        userInfoManager = UserInfoManager(herowDataStorage: herowDataHolder)
        apiManager = APIManager(connectInfo: connectionInfo, herowDataStorage: herowDataHolder, cacheManager: cacheManager, userInfoManager: userInfoManager)
        userInfoManager.registerListener(listener: apiManager)
        permissionsManager = PermissionsManager(userInfoManager: userInfoManager)
        appStateDetector.registerAppStateDelegate(appStateDelegate: userInfoManager)
        detectionEngine = DetectionEngine(locationManager, dataHolder:  dataHolder)
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
        liveMomentStore?.registerLiveMomentStoreListener(zoneProvider)
        cacheManager.registerCacheListener(listener: zoneProvider)
        detectionEngine.registerDetectionListener(listener: zoneProvider)
        analyticsManager = AnalyticsManager(apiManager: apiManager, cacheManager: cacheManager, dataStorage: herowDataHolder)
        redirectionCatcher = RedirectionsCatcher()
        analyticsManager.registerListener(listener: redirectionCatcher)
        liveMomentStore?.registerLiveMomentStoreListener(analyticsManager)
        appStateDetector.registerAppStateDelegate(appStateDelegate: analyticsManager)
        appStateDetector.registerAppStateDelegate(appStateDelegate: detectionEngine)
       
        detectionEngine.registerDetectionListener(listener: analyticsManager)
        detectionEngine.registerClickAndCollectListener(listener: analyticsManager)
     
        notificationManager = NotificationManager(cacheManager: cacheManager, notificationCenter:  notificationCenter, herowDataStorage: herowDataHolder)

        self.predictionStore = PredictionStore(dataBase: db)
        self.liveMomentStore?.registerLiveMomentStoreListener(predictionStore)
        self.predictionStore.registerListener(listener: userInfoManager)
       
        super.init()
        restoreShowsBackgroundLocationIndicatorOnAlwaysPermission()
        registerEventListener(listener: analyticsManager)
        detectionEngine.registerDetectionListener(listener: apiManager)
        registerEventListener(listener: notificationManager)
        notificationsOnExactZoneEntry(isNotificationsOnExactZoneEntry())
    }


    @objc public func getLocationsNumber() -> Int {
        return  db.getLocationsNumber()
    }

    @objc public func configPlatform(_ platform: HerowPlatform) -> HerowInitializer {
        connectionInfo.updatePlateform(platform)
        self.apiManager.configure(connectInfo: connectionInfo)
        return self
    }
    @available(*, deprecated, message: "Don't use this anymore, use configApp(sdkKey: String, sdkSecret: String) instead \n indentifier becomes sdkKey and sdkKey becomes sdkSecret")
    @objc public func configApp(identifier: String, sdkKey: String) -> HerowInitializer {
        self.apiManager.user = User(login: identifier, password: sdkKey)
        return self
    }

    @objc public func configApp(sdkKey: String, sdkSecret: String) -> HerowInitializer {
        self.apiManager.user = User(login: sdkKey, password: sdkSecret)
        return self
    }

    @objc public func synchronize(completion:(()->())? = nil) {
        detectionEngine.startWorking()
        self.apiManager.authenticationFlow {
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

    @objc public func reset(platform: HerowPlatform, sdkKey: String, sdkSecret: String ,customID: String, completion: @escaping ((String)->())) {
        let optinState = self.userInfoManager.getOptin()
        self.reset {
            self.userInfoManager.resetOptinsAndCustomId(optin: optinState, customId: customID)
            self.configPlatform(platform) .configApp(sdkKey: sdkKey, sdkSecret: sdkSecret).synchronize()
            completion(customID)
        }
    }
    //MARK: CUSTOM URLS MANAGEMENT

    func resetUrls() {
        let optins = getOptinValue()
        let config = connectionInfo
        let user = self.apiManager.user
        let exactEntry = self.isNotificationsOnExactZoneEntry()
        let customId = herowDataHolder.getCustomId()
        reset()
        self.notificationsOnExactZoneEntry(exactEntry)
        apiManager.configure(connectInfo: config)
        apiManager.user = user
        apiManager.reloadUrls()
        if let customId = customId {
            setCustomId(customId: customId)
        }
        synchronize()
        if optins {
            acceptOptin()
        } else {
            refuseOptin()
        }
    }

    @objc public func setProdCustomURL(_ url: String) {
        if URL(string: url) != nil {
            URLType.setProdCustomURL(url)
            if self.connectionInfo.platform == .prod {
                resetUrls()
            }
        }
    }

    @objc public func setPreProdCustomURL(_ url: String) {
        if URL(string: url) != nil {
            URLType.setPreProdCustomURL(url)
            if self.connectionInfo.platform == .preprod {
                resetUrls()
            }
        }
    }

    @objc public func activeLocationFilter(_ value: Bool) {
        self.detectionEngine.activeLocationFilter(value)
    }

    @objc public func removeCustomURL() {
        URLType.removeCustomURLS()
       resetUrls()
    }

    @objc public func useCustomURL() -> Bool {
        return URLType.useCustomURL()
    }
    
    @objc public func getCurrentURL() -> String {
        if self.connectionInfo.platform == .preprod {
            return URLType.getPreProdCustomURL()
        }
        return URLType.getProdCustomURL()
    }

    //MARK: REDIRECTIONS MANAGEMENT
    @objc public func registerRedirectionsListener(listener: RedirectionsListener) {
       redirectionCatcher.registerRedirectionsListener(listener)
   }



    //MARK: EVENTLISTENERS MANAGEMENT
    @objc public func registerEventListener(listener: EventListener) {
       eventDispatcher.registerListener(listener)

   }
    public func registerAnalyticsListener(_ listener: AnalyticsManagerListener) {
        self.analyticsManager.registerListener(listener: listener)

    }
    //MARK: CLICKANDCOLLECT MANAGEMENT

    @objc public func showsBackgroundLocationIndicatorOnAlwaysPermission(_ value: Bool) {
        dataHolder.putBoolean(key: "showsBackgroundLocationIndicator", value: value)
        detectionEngine.showsBackgroundLocationIndicator = value
    }

    @objc public func getShowsBackgroundLocationIndicatorOnAlwaysPermission() -> Bool {
       let value =  dataHolder.getBoolean(key: "showsBackgroundLocationIndicator")
        return value
    }
    private func restoreShowsBackgroundLocationIndicatorOnAlwaysPermission() {
        let value =  dataHolder.getBoolean(key: "showsBackgroundLocationIndicator")
        detectionEngine.showsBackgroundLocationIndicator = value
    }

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

    //MARK: DETECTIONENGINELISTENERS  MANAGEMENT
    @objc public func registerDetectionListener(listener: DetectionEngineListener) {
        detectionEngine.registerDetectionListener(listener:listener)
    }

    @objc public func unregisterDetectionListener(listener: DetectionEngineListener) {
        detectionEngine.unregisterDetectionListener(listener: listener)
    }

    public func getClickAndCollectStart() -> Date? {
        return dataHolder.getDate(key: "lastClickAndCollectActivationDate")
    }

    public func getClickAndCollectDelay() -> TimeInterval {
        if let activation = getClickAndCollectStart() {
            let now = Date()
            let limit = Date(timeInterval: StorageConstants.timeIntervalLimit, since: activation)
            let delay =
                (now <  limit ) ? DateInterval(start: now, end: limit).duration : 0
            return delay
        }
        return 0
    }

    //MARK: FUSEMANAGERLISTENERS  MANAGEMENT
    @objc public func  registerFuseManagerListener(listener: FuseManagerListener) {
        fuseManager.registerFuseManagerListener(listener:listener)
    }

    @objc public func unregisterFuseManagerListener(listener: FuseManagerListener) {
        fuseManager.unregisterFuseManagerListener(listener: listener)
    }

    //MARK: CACHELISTENERS  MANAGEMENT

    @objc public func getLastGeoHash() -> String? {
        return herowDataHolder.getLastGeoHash()
    }
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

    public   func reassignPeriodLocations(_ completion: @escaping()->()) {
        self.db.reassignPeriodLocations {
            completion()
        }
    }

    public   func recomputeRecurencies(_ completion: @escaping()->()) {
        self.db.reComputeRecurencies {
            completion()
        }
    }

    @objc public func getPatternForId(id: String) -> LocationPattern? {
        self.herowDataHolder.getLastZonesPredictions()?.filter {$0.zoneHash == id}.map {$0.pattern}.first
    }

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

    @objc static public func registerCoreDataCrashListener(_ listener: CoreDataManagerCrashListener) {
        if !HerowInitializer.coreDataListeners.contains(where: { $0 === listener }) {
            HerowInitializer.coreDataListeners.append(listener)
        }
    }

    //MARK: LiveMoment
    public func getClusters() -> [NodeDescription]? {
        return  liveMomentStore?.getClusters()?.getReccursiveRects(nil)
    }

    public func processOnlyOnCurrentGeoHash(_ value: Bool) {
        liveMomentStore?.processOnlyOnCurrentGeoHash(value)
    }

    public func registerLiveMomentStoreListener(listener: LiveMomentStoreListener) {
        liveMomentStore?.registerLiveMomentStoreListener(listener)
    }

    public func registerAppStateListener(listener: AppStateDelegate) {
        appStateDetector.registerAppStateDelegate(appStateDelegate: listener)
    }

    //MARK: Objects accessors
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

    public func getAllLocations(completion: @escaping ([QuadTreeLocation]) -> ())  {
        db.getLocations { locations in
            completion(locations)
        }
    }

    public func getPeriods( completion: @escaping ([PeriodProtocol]) -> ())  {
        db.getPeriods{ periods in
            completion(periods)
        }
    }

    public func removePeriods( period :PeriodProtocol ,completion: @escaping ([PeriodProtocol]) -> ())  {
        self.db.removePeriod(period: period) {
            self.db.getPeriods{ periods in
                completion(periods)
            }
        }
    }

    //MARK: UTILS
    @objc public func dispatchFakeLocation(_ location: CLLocation) {
        detectionEngine.dispatchFakeLocation(location)
    }

    @objc public func notificationsOnExactZoneEntry(_ value: Bool) {
        herowDataHolder.setUseExactEntry(value)
        notificationManager.notificationsOnExactZoneEntry(value)
    }

     @objc public func isNotificationsOnExactZoneEntry() -> Bool {
      return  herowDataHolder.useExactEntry()
    }

    @objc public func getVersion() -> String {
        return AnalyticsInfo().libInfo.version
    }

    public  func computeDynamicContent(_ text:  String, zone: Zone, campaign: Campaign) -> String {
        let dynamicValues =  text.dynamicValues(for: "\\{\\{(.*?)\\}\\}")
        var result = dynamicValues.newText
        let defaultValues = dynamicValues.defaultValues
        GlobalLogger.shared.debug("create dynamic content notification: \(campaign.getId())")
        DynamicKeys.allCases.forEach() { key in
            var value = ""
            switch key {
            case .name:
                value = zone.getAccess()?.getName() ?? (defaultValues[key.rawValue] ?? "")
            case .radius:
                value = "\(zone.getRadius())"
            case .address:
                value = zone.getAccess()?.getAddress() ??  (defaultValues[key.rawValue] ?? "")
            case .customId:
                value = herowDataHolder.getCustomId() ??  (defaultValues[key.rawValue] ?? "")
            }
            GlobalLogger.shared.debug("dynamic content replacing by key : \(DynamicKeys.name.rawValue) with \( String(describing: zone.getAccess()?.getName()))")
            GlobalLogger.shared.debug("dynamic content replacing by key : \(DynamicKeys.radius.rawValue) with \(zone.getRadius())")
            GlobalLogger.shared.debug("dynamic content replacing by key : \(DynamicKeys.address.rawValue) with \(String(describing: zone.getAccess()?.getAddress()))")
            GlobalLogger.shared.debug("dynamic content replacing by key : \(DynamicKeys.customId.rawValue) with \( String(describing: herowDataHolder.getCustomId()))")
            GlobalLogger.shared.debug("dynamic content replacing: \(key.rawValue) with \(value)")
            result = result.replacingOccurrences(of: key.rawValue, with: value)
        }
        GlobalLogger.shared.debug("create dynamic content notification: \(text)")
        GlobalLogger.shared.debug("create dynamic content notification tupple: \(dynamicValues)")
        GlobalLogger.shared.debug("create dynamic content notification result: \(result)")
        return result
    }
}

extension UNUserNotificationCenter : NotificationCenterProtocol {

}
