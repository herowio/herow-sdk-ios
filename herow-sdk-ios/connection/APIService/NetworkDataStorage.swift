//
//  NetworkDataStorage.swift
//  herow-sdk-ios
//
//  Created by Damien on 20/01/2021.
//

import Foundation

public protocol NetworkDataStorageProtocol {
    func saveToken(_ token: APIToken)
    func saveUserInfo(_ userInfo: APIUserInfo)
    func saveConfig(_ config: APIConfig)
    func getToken() -> APIToken?
    func getUserInfo() -> APIUserInfo?
    func getConfig() -> APIConfig?
    func tokenIsExpired() -> Bool

}
public class NetworkDataStorage: NetworkDataStorageProtocol {

    let dataHolder: DataHolder

    init(dataHolder: DataHolder) {
        self.dataHolder = dataHolder
    }
    
    public func saveToken(_ token: APIToken) {
        var aToken = token
        aToken.expirationDate = Date().addingTimeInterval(TimeInterval(aToken.expiresIn))
        guard let data = aToken.encode() else {
            return
        }
        dataHolder.putData(key: ConnexionConstant.tokenKey, value: data)
        dataHolder.apply()
    }

    public func getToken() -> APIToken? {

        guard let data = dataHolder.getData(key: ConnexionConstant.tokenKey) else {
            return nil
        }
        guard let token = APIToken.decode(data: data)  else {
            return nil
        }
        return token
    }
    
    public func saveUserInfo(_ userInfo: APIUserInfo) {
        guard let data = userInfo.encode() else {
            return
        }
        dataHolder.putData(key: ConnexionConstant.userInfoKey, value: data)
        dataHolder.apply()
    }

    public func getUserInfo() -> APIUserInfo? {
        guard let data = dataHolder.getData(key: ConnexionConstant.userInfoKey) else {
            return nil
        }
        guard let userInfo = APIUserInfo.decode(data: data)  else {
            return nil
        }
        return userInfo
    }

    public func tokenIsExpired() -> Bool {
        guard let token = getToken(), let date = token.expirationDate else {
            return true
        }
        return date < Date()
    }

    public func getConfig() -> APIConfig? {
        guard let data = dataHolder.getData(key: ConnexionConstant.configKey) else {
            return nil
        }
        guard let config = APIConfig.decode(data: data)  else {
            return nil
        }
        return config
    }

    public func saveConfig(_ config: APIConfig) {
        guard let data = config.encode() else {
            return
        }
        dataHolder.putData(key: ConnexionConstant.configKey, value: data)
        dataHolder.apply()
    }
}
