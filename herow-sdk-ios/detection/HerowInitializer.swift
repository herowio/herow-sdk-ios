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
    private var apiManager: APIManager
    private var netWorkDataHolder: NetworkDataStorageProtocol
    private var dataHolder: DataHolder
    private var connectionInfo : ConnectionInfo
    private var userInfoManager: UserInfoManagerProtocol
    private var permissionsManager: PermissionsManagerProtocol
    private override init() {
        dataHolder = DataHolderUserDefaults(suiteName: "HerowInitializer")
        netWorkDataHolder = NetworkDataStorage(dataHolder: dataHolder)
        connectionInfo = ConnectionInfo()
        apiManager = APIManager(connectInfo: connectionInfo , netWorkDataStorage: netWorkDataHolder)
        userInfoManager = UserInfoManager(apiManager:  apiManager)
        permissionsManager = PermissionsManager(userInfoManager: userInfoManager, dataHolder: dataHolder)
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

        let location = CLLocation(latitude: 49.37, longitude: 3.898)
        let currentGeoHash = GeoHashHelper.encodeBase32(lat: location.coordinate.latitude, lng: location.coordinate.longitude)[0...3]
            self.apiManager.getCache(geoHash: String(currentGeoHash))

    }
}
