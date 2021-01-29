//
//  APIManager.swift
//  herow-sdk-ios
//
//  Created by Damien on 19/01/2021.
//

import Foundation
import CoreLocation

public enum NetworkError: Error {
    case badUrl
    case invalidStatusCode
    case invalidInPut
    case invalidResponse
    case noData
    case serialization
}

public enum URLType: String {
    case  preprod = "https://m-preprod.herow.io"
    case  prod = "https://m.herow.io"
}

public enum EndPoint {
    case undefined
    case token
    case config
    case userInfo
    case cache(_ last : String)

    var value: String {
        switch self {
        case .token:
            return "/auth/authorize/token"
        case .config:
            return "/v2/sdk/config"
        case .userInfo:
            return "/v2/sdk/userinfo"
        case .cache(let last):
            return "/v2/sdk/cache/content/\(last)"
        default:
            return ""
        }
    }
}

protocol ConfigDispatcher {
    func dispatchConfig( _ config: APIConfig)
}

protocol ConfigListener:  class {
    func didRecievedConfig( _ config: APIConfig)
}

protocol APIManagerProtocol:ConfigDispatcher {
    var currentUserInfo: UserInfo? {get set}
    func getConfig(completion: ( (APIConfig?, NetworkError?) -> Void)?)
    func getConfigIfNeeded(completion:(()->())?)
    func getUserInfo(completion: ( (APIUserInfo?, NetworkError?) -> Void)?)
    func getCache(geoHash: String, completion: ( (APICache?, NetworkError?) -> Void)?)
    func getUserInfoIfNeeded(completion: (() -> Void)?)
}

public class APIManager: NSObject, APIManagerProtocol, DetectionEngineListener {

    let tokenWorker: APIWorker<APIToken>
    let configWorker: APIWorker<APIConfig>
    let userInfogWorker: APIWorker<APIUserInfo>
    let cacheWorker: APIWorker<APICache>
    let herowDataStorage:HerowDataStorageProtocol
    var currentUserInfo: UserInfo?
    let cacheManager: CacheManagerProtocol
    let dateFormatter = DateFormatter()
    private var listeners = [WeakContainer<ConfigListener>]()
    private  var connectInfo: ConnectionInfo
    var user: User?
    init(connectInfo: ConnectionInfo, herowDataStorage: HerowDataStorageProtocol, cacheManager: CacheManagerProtocol) {
        self.herowDataStorage = herowDataStorage
        self.connectInfo = connectInfo
        self.cacheManager = cacheManager
        let urlType = self.connectInfo.getUrlType()
        self.tokenWorker = APIWorker<APIToken>(urlType: urlType, endPoint: .token)
        self.configWorker = APIWorker<APIConfig>(urlType: urlType, endPoint: .config)
        self.userInfogWorker = APIWorker<APIUserInfo>(urlType: urlType, endPoint: .userInfo)
        self.cacheWorker = APIWorker<APICache>(urlType: urlType)
    }

    private func encodeFormParams(dictionary: [String: String]) -> Data {
        var parts: [String] = []
        for (key, value) in dictionary {
            parts.append("\(key)=\(value)")
        }
        let encodeResult = parts.joined(separator: "&")
        return encodeResult.data(using: String.Encoding.utf8)!
    }

    private func getTokenIfNeeded(completion:  @escaping ()->()) {
        if self.herowDataStorage.tokenIsExpired() {
            GlobalLogger.shared.debug("APIManager - token expired")
            self.getAndSaveToken(completion: {_,_ in
                completion()
            })
        }else {
            GlobalLogger.shared.debug("APIManager - token not expired")
            completion()
        }
    }

    private func authenticationFlow(completion: @escaping ()->()) {
        getConfigIfNeeded {
            completion()
        }
    }

    func getConfigIfNeeded(completion:(()->())? = nil) {
        if self.herowDataStorage.shouldGetConfig() {
            GlobalLogger.shared.debug("APIManager - should get config")
            self.getConfig(completion: {_,_ in
                completion?()
                if let config = self.herowDataStorage.getConfig() {
                    self.dispatchConfig(config)
                }
            })
        } else {
            GlobalLogger.shared.debug("APIManager - config not expired")
            self.getTokenIfNeeded {
                completion?()
                if let config = self.herowDataStorage.getConfig() {
                    self.dispatchConfig(config)
                }
            }
        }
    }

    public func getUserInfoIfNeeded(completion: (() -> Void)? = nil) {
        if self.herowDataStorage.userInfoWaitingForUpdate()  {
            GlobalLogger.shared.debug("APIManager - should get userInfo")

            self.getUserInfo(completion: { userInfo, error in
                if userInfo?.herowId != nil {
                    self.herowDataStorage.saveUserInfoWaitingForUpdate(false)
                }
                completion?()
            }

            )
        } else {
            self .getTokenIfNeeded {
                GlobalLogger.shared.debug("APIManager - userInfos exists")
                completion?()
            }
        }
    }

    private func getAndSaveToken( completion: @escaping (APIToken?, NetworkError?) -> Void) {
        getToken() { token, error in
            var tempToken = token
            if let token = token {
                self.herowDataStorage.saveToken(token)
                tempToken = self.herowDataStorage.getToken()
            }
            GlobalLogger.shared.debug("APIManager - token request: \(String(describing: tempToken)) error: \(String(describing: error))")
            completion(tempToken,error)
        }
    }

    private func getToken(completion: @escaping (APIToken?, NetworkError?) -> Void) {
        guard let user = user  else {
            completion(nil,.invalidInPut)
            return
        }
        tokenWorker.postData(param: tokenParam(user), completion: completion)
    }

    public func configure(connectInfo: ConnectionInfo) {
        let urlType = connectInfo.getUrlType()
        self.connectInfo = connectInfo
        self.tokenWorker.setUrlType(urlType)
        self.configWorker.setUrlType(urlType)
        self.userInfogWorker .setUrlType(urlType)
        self.cacheWorker .setUrlType(urlType)
    }

    public func getConfig(completion: ( (APIConfig?, NetworkError?) -> Void)? = nil) {
        getUserInfoIfNeeded() {
            self.configWorker.headers = RequestHeaderCreator.createHeaders(token: self.herowDataStorage.getToken()?.accessToken,herowId: self.herowDataStorage.getUserInfo()?.herowId)
            self.configWorker.getData() {
                config, error in
                if let config = config {
                    self.herowDataStorage.saveConfig(config)
                    if let lastTimeCacheWasModified =  self.configWorker.responseHeaders?[Headers.lastTimeCacheModified] as? String {
                        self.dateFormatter.dateFormat = DateFormat.lastModifiedDateFormat
                        if let date = self.dateFormatter.date(from: lastTimeCacheWasModified) {
                            self.herowDataStorage.saveLastCacheModifiedDate(date)
                        }
                    }
                }
                GlobalLogger.shared.debug("APIManager - config request: \(String(describing: config)) error: \(String(describing: error))")
                completion?(config, error)
            }
        }
    }

    public func getUserInfo(completion: ( (APIUserInfo?, NetworkError?) -> Void)? = nil) {
        getTokenIfNeeded {
            self.userInfogWorker.headers = RequestHeaderCreator.createHeaders(token: self.herowDataStorage.getToken()?.accessToken)
            self.userInfogWorker.putData(param:self.userInfoParam()) { userInfo, error in
                if let userInfo = userInfo {
                    self.herowDataStorage.saveUserInfo(userInfo)
                }
                GlobalLogger.shared.debug("APIManager - userInfo request: \(String(describing: userInfo)) error: \(String(describing: error))")
                completion?(userInfo, error)
            }
        }
    }

    

    public func getCache(geoHash: String, completion: ( (APICache?, NetworkError?) -> Void)? = nil) {
        authenticationFlow  {
            if self.herowDataStorage.shouldGetCache(for: geoHash) {
                GlobalLogger.shared.debug("APIManager- SHOULD FETCH CACHE")

                self.cacheWorker.headers = RequestHeaderCreator.createHeaders(token:self.herowDataStorage.getToken()?.accessToken, herowId: self.herowDataStorage.getUserInfo()?.herowId)
                self.cacheWorker.getData(endPoint: .cache(geoHash)) { cache, error in
                    guard let cache = cache else {
                        return
                    }

                    self.herowDataStorage.saveLastCacheFetchDate(Date())
                    self.herowDataStorage.setLastGeohash(geoHash)
                    self.cacheManager.cleanCache()
                    self.cacheManager.save(zones: cache.zones,
                                           campaigns: cache.campaigns,
                                           pois: cache.pois, completion: nil)
                    completion?(cache, error)
                }
            } else {
                GlobalLogger.shared.debug("APIManager- NO NEED TO FETCH CACHE")
            }
        }
    }

    private func tokenParam(_ user: User) -> Data {
        
        let credentials = self.connectInfo.platform.credentials
        let params = [Parameters.username: user.login,
                      Parameters.password: user.password,
                      Parameters.clientId:  credentials.clientId,
                      Parameters.clientSecret: credentials.clientSecret,
                      Parameters.redirectUri: credentials.redirectURI,
                      Parameters.grantType : "password"]
        return self.encodeFormParams(dictionary: params)
    }

    private func userInfoParam() -> Data? {
        var result: Data?
        let encoder = JSONEncoder()
        do {
            result = try encoder.encode(currentUserInfo)

        } catch {
            print("error while encoding userInfo : \(error.localizedDescription)")
        }
        return result
    }


    func dispatchConfig(_ config: APIConfig) {
        for listener in self.listeners {
            listener.get()?.didRecievedConfig(config)
        }
    }

    func registerConfigListener(listener: ConfigListener) {
        let first = listeners.first {
            ($0.get() === listener) == true
        }
        if first == nil {
            listeners.append(WeakContainer<ConfigListener>(value: listener))
        }
    }

    public func unregisterConfigListener(listener: DetectionEngineListener) {
        listeners = listeners.filter {
            ($0.get() === listener) == false
        }
    }

    public func onLocationUpdate(_ location: CLLocation) {
        let currentGeoHash = GeoHashHelper.encodeBase32(lat: location.coordinate.latitude, lng: location.coordinate.longitude)[0...3]
        getCache(geoHash: String(currentGeoHash))
    }

}
