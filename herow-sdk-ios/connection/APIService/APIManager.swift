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
    case noOptin
}

public enum URLType: String {
    case  badURL = ""
    case  test = "https://herow-sdk-backend-poc.ew.r.appspot.com"
    case  preprod = "https://sdk7-preprod.herow.io"
    case  prod = "https://sdk7.herow.io"
}

public enum EndPoint {
    case undefined
    case test
    case token
    case config
    case userInfo
    case log
    case cache(_ last : String)

    var value: String {
        switch self {
        case .token:
            return "/auth/authorize/token"
        case .config:
            return "/v2/sdk/config"
        case .userInfo:
            return "/v2/sdk/userinfo"
        case .log:
            return "/stat/queue"
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

protocol ConfigListener:  AnyObject {
    func didRecievedConfig( _ config: APIConfig)
}

protocol APIManagerProtocol:ConfigDispatcher {
    var currentUserInfo: UserInfo? {get set}
    func getConfig(completion: ( (APIConfig?, NetworkError?) -> Void)?)
    func getConfigIfNeeded(completion:(()->())?)
    func getUserInfo(completion: ( (APIUserInfo?, NetworkError?) -> Void)?)
    func getCache(geoHash: String, completion: ( (APICache?, NetworkError?) -> Void)?)
    func getUserInfoIfNeeded(completion: (() -> Void)?)
    func pushLog(_ log: Data ,completion: (() -> Void)?)
}

public class APIManager: NSObject, APIManagerProtocol, DetectionEngineListener, RequestStatusListener, UserInfoListener {

    let tokenWorker: APIWorker<APIToken>
    let configWorker: APIWorker<APIConfig>
    let userInfogWorker: APIWorker<APIUserInfo>
    let cacheWorker: APIWorker<APICache>
    let logWorker: APIWorker<NoReply>
    let herowDataStorage:HerowDataStorageProtocol
    var currentUserInfo: UserInfo?
    let cacheManager: CacheManagerProtocol
    let dateFormatter = DateFormatter()
    private var listeners = [WeakContainer<ConfigListener>]()
    private  var connectInfo: ConnectionInfoProtocol
    var user: User?
    init(connectInfo: ConnectionInfoProtocol, herowDataStorage: HerowDataStorageProtocol, cacheManager: CacheManagerProtocol) {
        // setting infos storage
        self.herowDataStorage = herowDataStorage
        self.connectInfo = connectInfo
        self.cacheManager = cacheManager
        let urlType = self.connectInfo.getUrlType()
        // workers initialization
        self.tokenWorker = APIWorker<APIToken>(urlType: urlType, endPoint: .token)
        self.configWorker = APIWorker<APIConfig>(urlType: urlType, endPoint: .config)
        self.userInfogWorker = APIWorker<APIUserInfo>(urlType: urlType, endPoint: .userInfo)
        self.logWorker = APIWorker<NoReply>(urlType: urlType, endPoint: .log)
        self.cacheWorker = APIWorker<APICache>(urlType: urlType)
        super.init()
        // setting status code listening
        self.cacheWorker.statusCodeListener = self
        self.configWorker.statusCodeListener = self
        self.userInfogWorker.statusCodeListener = self
    }

    func didReceiveResponse(_ statusCode: Int) {
        if statusCode == HttpStatusCode.HTTP_TOO_MANY_REQUESTS {
            // TODO:  save date and retry after delais
        }
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

                if let config = self.herowDataStorage.getConfig() {
                    self.dispatchConfig(config)
                }
                completion?()
            })
        } else {
            GlobalLogger.shared.debug("APIManager - config not expired")
            self.getTokenIfNeeded {

                if let config = self.herowDataStorage.getConfig() {
                    self.dispatchConfig(config)
                }
                completion?()
            }
        }
    }

    public func getUserInfoIfNeeded(completion: (() -> Void)? = nil) {
        if self.herowDataStorage.userInfoWaitingForUpdate()  {
            GlobalLogger.shared.debug("APIManager - should get userInfo")

            self.getUserInfo(completion: { userInfo, error in
                if let userInfo = userInfo  {
                    self.herowDataStorage.saveUserInfo(userInfo)
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


    public func configure(connectInfo: ConnectionInfoProtocol) {
        let urlType = connectInfo.getUrlType()
        self.connectInfo = connectInfo
        self.tokenWorker.setUrlType(urlType)
        self.configWorker.setUrlType(urlType)
        self.userInfogWorker .setUrlType(urlType)
        self.logWorker.setUrlType(urlType)
        self.cacheWorker .setUrlType(urlType)
    }
    // MARK: Token
    private func getToken(completion: @escaping (APIToken?, NetworkError?) -> Void) {
        guard let user = user  else {
            completion(nil,.invalidInPut)
            return
        }

        let headers = RequestHeaderCreator.createHeaders(sdk:  self.user?.login, token: self.herowDataStorage.getToken()?.accessToken)
        tokenWorker.headers = headers
        tokenWorker.postData(param: tokenParams(user), completion: completion)
    }

    // MARK: Config
    internal func getConfig(completion: ( (APIConfig?, NetworkError?) -> Void)? = nil) {

        getUserInfoIfNeeded() {
            self.configWorker.headers = RequestHeaderCreator.createHeaders(sdk:  self.user?.login, token: self.herowDataStorage.getToken()?.accessToken,herowId: self.herowDataStorage.getUserInfo()?.herowId)
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
                if error == nil {
                    GlobalLogger.shared.debug("APIManager - config request: \(String(describing: config)) error: \(String(describing: error))")
                }
                completion?(config, error)
            }
        }
    }
    
    // MARK: UserInfo
    internal func getUserInfo(completion: ( (APIUserInfo?, NetworkError?) -> Void)? = nil) {
        getTokenIfNeeded {
            self.userInfogWorker.headers = RequestHeaderCreator.createHeaders(sdk:  self.user?.login, token: self.herowDataStorage.getToken()?.accessToken)
            self.userInfogWorker.putData(param:self.userInfoParam()) { userInfo, error in
                if let userInfo = userInfo {
                    self.herowDataStorage.saveUserInfo(userInfo)
                }
                if error == nil {
                    GlobalLogger.shared.debug("APIManager - userInfo request: \(String(describing: userInfo)) error: \(String(describing: error))")
                }
                completion?(userInfo, error)
            }
        }
    }

    // MARK: Cache
    internal func getCache(geoHash: String, completion: ( (APICache?, NetworkError?) -> Void)? = nil) {
        if  !herowDataStorage.getOptin().value {
            GlobalLogger.shared.verbose("APIManager- OPTINS ARE FALSE")
            completion?(nil, NetworkError.noOptin)
            return
        }
        authenticationFlow  {
            if self.herowDataStorage.shouldGetCache(for: geoHash) {
                GlobalLogger.shared.info("APIManager- SHOULD FETCH CACHE")
                self.cacheWorker.headers = RequestHeaderCreator.createHeaders(sdk:  self.user?.login , token:self.herowDataStorage.getToken()?.accessToken, herowId: self.herowDataStorage.getUserInfo()?.herowId)

                self.cacheWorker.getData(endPoint: .cache(geoHash)) { cache, error in
                    guard let cache = cache else {
                        return
                    }
                    GlobalLogger.shared.info("APIManager- CACHE HAS BEEN FETCHED")
                    GlobalLogger.shared.verbose("APIManager- received cache: \(cache)")
                    self.herowDataStorage.saveLastCacheFetchDate(Date())
                    self.herowDataStorage.setLastGeohash(geoHash)
                    self.cacheManager.cleanCache() {
                        self.cacheManager.save(zones: cache.zones,
                                               campaigns: cache.campaigns,
                                               pois: cache.pois, completion: nil)
                        completion?(cache, error)
                    }
                }
            } else {
                self.cacheManager.didSave()
                GlobalLogger.shared.info("APIManager- NO NEED TO FETCH CACHE")
            }
        }
    }
    // MARK: Logs
    internal func pushLog(_ log: Data,completion: (() -> Void)?) {
        if  !herowDataStorage.getOptin().value {
            GlobalLogger.shared.info("APIManager- OPTINS ARE FALSE")
            return
        }
        authenticationFlow  {
            self.logWorker.headers = RequestHeaderCreator.createHeaders(sdk: self.user?.login, token:self.herowDataStorage.getToken()?.accessToken, herowId: self.herowDataStorage.getUserInfo()?.herowId)
            self.logWorker.postData(param: log) {
                response, error in

                if error == nil {
                    if let json = try? JSONSerialization.jsonObject(with: log, options: .mutableContainers),
                       let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) {
                        GlobalLogger.shared.verbose("APIManager - sendlog: \n \(String(decoding: jsonData, as: UTF8.self))")
                    } 
                }
            }
        }
    }
    // MARK: Params
   /* private func tokenParam(_ user: User) -> Data {
        
        let credentials = self.connectInfo.platform.credentials
        let params = [Parameters.username: user.login,
                      Parameters.password: user.password,
                      Parameters.clientId:  credentials.clientId,
                      Parameters.clientSecret: credentials.clientSecret,
                      Parameters.redirectUri: credentials.redirectURI,
                      Parameters.grantType : "password"]
        return self.encodeFormParams(dictionary: params)
    }*/
    

    private func tokenParams(_ user: User) -> Data {
        var result: Data?
        let encoder = JSONEncoder()
        let credentials = self.connectInfo.platform.credentials
        do {
            let params = [Parameters.username: user.login,
                          Parameters.password: user.password,
                          Parameters.clientId:  credentials.clientId,
                          Parameters.clientSecret: credentials.clientSecret,
                          Parameters.redirectUri: credentials.redirectURI,
                          Parameters.grantType : "password"]

            result = try encoder.encode(params)
            if let result = result {
            GlobalLogger.shared.debug("APIManager - token infos to send: \(String(decoding: result, as: UTF8.self))")
            }

        } catch {
            print("error while encoding userInfo : \(error.localizedDescription)")
        }
        return result ?? Data()

    }
    private func userInfoParam() -> Data? {
        var result: Data?
        let encoder = JSONEncoder()
        do {

            result = try encoder.encode(currentUserInfo)
            if let result = result {
            GlobalLogger.shared.debug("APIManager - userInfo to send: \(String(decoding: result, as: UTF8.self))")
            }

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

   public func onLocationUpdate(_ location: CLLocation, from: UpdateType) {
        let currentGeoHash = GeoHashHelper.encodeBase32(lat: location.coordinate.latitude, lng: location.coordinate.longitude)[0...3]
      
        getCache(geoHash: String(currentGeoHash))
    }

    public func onUserInfoUpdate(userInfo: UserInfo) {
        self.currentUserInfo = userInfo
        self.getUserInfoIfNeeded {
            GlobalLogger.shared.debug("APIManager - userInfo request because update")
        }
    }
}
