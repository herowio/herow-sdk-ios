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
    case noNetwork
    case invalidStatusCode
    case invalidInPut
    case invalidResponse
    case noData
    case serialization
    case noOptin
    case requestExistsInQueue
    case workerStillWorking
    case backgroundTaskExpiration
}

public enum URLType {
    static let prodCustomURLKey = "prodCustomURLKey"
    static let preProdCustomURLKey = "preProdCustomURLKey"
    static let defaultPreprodURL = "https://sdk7-preprod.herow.io"
    static let defaultProdURL = "https://sdk7.herow.io"
    static let defaultTestURL = "https://herow-sdk-backend-poc.ew.r.appspot.com"

    static let userDefault =  UserDefaults.init(suiteName: "URLType")
    case  badURL
    case  test
    case  preprod
    case  prod

    var value: String {
        switch self {
        case .badURL:
            return ""
        case .test:
            return URLType.defaultTestURL
        case .preprod:
            return URLType.getPreProdCustomURL()
        case .prod:
            return  URLType.getProdCustomURL() 
        }
    }

    public static func setProdCustomURL(_ url: String) {

        URLType.userDefault?.setValue(url, forKey: URLType.prodCustomURLKey)
        URLType.userDefault?.synchronize()
    }
    public static func setPreProdCustomURL(_ url: String) {

        URLType.userDefault?.setValue(url, forKey: URLType.preProdCustomURLKey)
        URLType.userDefault?.synchronize()
    }

    public static func  removeCustomURLS() {

        URLType.userDefault?.removeObject(forKey: URLType.prodCustomURLKey)
        URLType.userDefault?.removeObject(forKey: URLType.preProdCustomURLKey)
        URLType.userDefault?.synchronize()
    }

    public static func getProdCustomURL() -> String {
        return  URLType.userDefault?.string(forKey: URLType.prodCustomURLKey) ??  URLType.defaultProdURL
    }
    
    public static func getPreProdCustomURL() -> String {
        return URLType.userDefault?.string(forKey: URLType.preProdCustomURLKey) ?? URLType.defaultPreprodURL

    }

   static func useCustomURL() -> Bool {
        return URLType.userDefault?.string(forKey: URLType.preProdCustomURLKey) != nil ||  URLType.userDefault?.string(forKey: URLType.prodCustomURLKey)  != nil
    }
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
    func pushLog(_ log: Data, _ logtype: String ,completion: (() -> Void)?)
    func reset()
    func reloadUrls()
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
    private  var connectInfo: ConnectionInfoProtocol?
    private var userInfoManager: UserInfoManagerProtocol?
    var user: User?
    var cacheLoading = false
    init(connectInfo: ConnectionInfoProtocol, herowDataStorage: HerowDataStorageProtocol, cacheManager: CacheManagerProtocol, userInfoManager: UserInfoManagerProtocol? = nil ) {
        // setting infos storage
        self.herowDataStorage = herowDataStorage
        self.userInfoManager = userInfoManager
        self.connectInfo = connectInfo
        self.cacheManager = cacheManager
        let urlType = self.connectInfo?.getUrlType() ?? .prod
        // workers initialization
        self.tokenWorker = APIWorker<APIToken>(urlType: urlType, endPoint: .token)
        self.configWorker = APIWorker<APIConfig>(urlType: urlType, endPoint: .config)
        self.userInfogWorker = APIWorker<APIUserInfo>(urlType: urlType, endPoint: .userInfo)
        self.logWorker = APIWorker<NoReply>(urlType: urlType, endPoint: .log, allowMultiOperation: true)
        self.cacheWorker = APIWorker<APICache>(urlType: urlType)
        super.init()
        // setting status code listening
        self.tokenWorker.statusCodeListener = self
        self.logWorker.statusCodeListener = self
        self.cacheWorker.statusCodeListener = self
        self.configWorker.statusCodeListener = self
        self.userInfogWorker.statusCodeListener = self
    }

    func reset() {
        self.user = nil
        self.currentUserInfo = nil
        resetWorkers()
    }

    func resetWorkers() {
        self.tokenWorker.reset()
        self.cacheWorker.reset()
        self.configWorker.reset()
        self.logWorker.reset()
        self.userInfogWorker.reset()
    }

    func didReceiveResponse(_ statusCode: Int) {
        if statusCode == HttpStatusCode.HTTP_TOO_MANY_REQUESTS {
            // TODO:  save date and retry after delais
        }
        if statusCode == HttpStatusCode.HTTP_BAD_REQUEST || statusCode == HttpStatusCode.HTTP_UNAUTHORIZED {

            GlobalLogger.shared.error("Remove API token")
            self.herowDataStorage.removeToken()
            resetWorkers()
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

    public func authenticationFlow(completion: @escaping ()->()) {
        self.getTokenIfNeeded {
            self.getUserInfoIfNeeded {
                self.getConfigIfNeeded(completion: completion)
            }
        }
    }

    func getConfigIfNeeded(completion:(()->())? = nil) {

        GlobalLogger.shared.debug("APIManager - getConfigIfNeeded")
        let process = {
            if let config = self.herowDataStorage.getConfig() {
                self.dispatchConfig(config)
            }
            completion?()
        }

        if self.herowDataStorage.shouldGetConfig() {
            GlobalLogger.shared.debug("APIManager - should get config")
            self.getConfig(completion: {_,_ in
              process()
            })
        } else {
            process()
        }
    }

    public func getUserInfoIfNeeded(completion: (() -> Void)? = nil) {
        if self.herowDataStorage.userInfoWaitingForUpdate()  {
            GlobalLogger.shared.debug("APIManager - should get userInfo")
            self.getUserInfo(completion: {  [unowned self ] userInfo, error in
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
        getToken() {   [unowned self ] token, error in
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
        self.connectInfo = connectInfo
              reloadUrls()
    }

    func reloadUrls() {
            guard let urlType = self.connectInfo?.getUrlType() else {
                return
            }
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
        guard let user = self.user, let herowid = self.herowDataStorage.getUserInfo()?.herowId else {
            completion?(nil, .invalidInPut)
            return
        }
        getTokenIfNeeded { [unowned self ] in

                self.configWorker.headers = RequestHeaderCreator.createHeaders(sdk:  user.login, token: self.herowDataStorage.getToken()?.accessToken,herowId: herowid)
                self.configWorker.getData() {
                    config, error in
                    if let config = config {
                        self.herowDataStorage.saveConfig(config)

                        let tmpValue = self.configWorker.responseHeaders?[Headers.lastTimeCacheModified] ?? self.configWorker.responseHeaders?[Headers.lastTimeCacheModifiedUpper]
                        if let lastTimeCacheWasModified =  tmpValue as? String {
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
        guard let user = self.user, let _ =  self.herowDataStorage.getToken()?.accessToken else {
            completion?(nil, .invalidInPut)
            return
        }
        getTokenIfNeeded {  [unowned self ] in
            self.userInfogWorker.headers = RequestHeaderCreator.createHeaders(sdk:  user.login, token: self.herowDataStorage.getToken()?.accessToken)
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

        GlobalLogger.shared.debug("APIManager - getCache")
        if  !herowDataStorage.getOptin().value {
            GlobalLogger.shared.verbose("APIManager- OPTINS ARE FALSE")
            completion?(nil, NetworkError.noOptin)
            self.cacheLoading =  false
            return
        }
        if cacheLoading {
            GlobalLogger.shared.verbose("APIManager- CACHE ALREADY LOADING")
           // return
        }
        cacheLoading = true
        authenticationFlow  {
            [unowned self ] in
            guard let user = self.user, let herowid = self.herowDataStorage.getUserInfo()?.herowId else {
                completion?(nil, .invalidInPut)
                return
            }
            if self.herowDataStorage.shouldGetCache(for: geoHash) /*|| true*/ {
                GlobalLogger.shared.info("APIManager- SHOULD FETCH CACHE")
                self.cacheWorker.headers = RequestHeaderCreator.createHeaders(sdk: user.login , token:self.herowDataStorage.getToken()?.accessToken, herowId: herowid)

                self.cacheWorker.getData(endPoint: .cache(geoHash)) { cache, error in
                    guard let cache = cache else {
                        return
                    }
                    GlobalLogger.shared.info("APIManager- CACHE HAS BEEN FETCHED")
                    GlobalLogger.shared.verbose("APIManager- received cache: \(cache)")
                    self.herowDataStorage.saveLastCacheFetchDate(Date())

                    self.cacheManager.cleanCache() {
                        self.cacheManager.save(zones: cache.zones,
                                               campaigns: cache.campaigns,
                                               pois: cache.pois, completion: {
                                                self.cacheLoading =  false
                                                self.cacheManager.didSave(forGeoHash: geoHash)
                                                self.herowDataStorage.setLastGeohash(geoHash)
                                               })
                        completion?(cache, error)
                    }
                    self.cacheLoading =  false
                }
            } else {
                self.cacheManager.didSave(forGeoHash: nil)
                GlobalLogger.shared.info("APIManager- NO NEED TO FETCH CACHE")
                self.cacheLoading =  false
            }
        }
    }
    // MARK: Logs
    internal func pushLog(_ log: Data, _ logtype: String = "",completion: (() -> Void)?) {
        if  !herowDataStorage.getOptin().value {
            GlobalLogger.shared.info("APIManager- OPTINS ARE FALSE")
            return
        }
        guard let user = self.user, let herowid = self.herowDataStorage.getUserInfo()?.herowId else {
            completion?()
            return
        }
        authenticationFlow  {  [unowned self ] in
            self.logWorker.headers = RequestHeaderCreator.createHeaders(sdk: user.login, token:self.herowDataStorage.getToken()?.accessToken, herowId: herowid)

            self.logWorker.postData(param: log) {
                response, error in

                if error == nil {
                    if let json = try? JSONSerialization.jsonObject(with: log, options: .mutableContainers),
                       let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) {
                        GlobalLogger.shared.verbose("APIManager - send log - nature:  \(logtype) \n \(String(decoding: jsonData, as: UTF8.self)) response:\(String(describing: response))")
                    } 
                }
                completion?()
            }
        }
    }
    // MARK: Params

    private func tokenParams(_ user: User) -> Data {
        var result: Data?
        let encoder = JSONEncoder()
        guard  let credentials = self.connectInfo?.platform.credentials else {
            return Data()
        }
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
        var userInfo = currentUserInfo
        if let myUserInfo = userInfoManager?.getUserInfo() {
            userInfo = myUserInfo
        }
        do {

            result = try encoder.encode(userInfo)
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
        GlobalLogger.shared.debug("APIManager - onLocationUpdate")
        getConfigIfNeeded {  [unowned self ] in
            self.getUserInfoIfNeeded {
                self.getCache(geoHash: String(currentGeoHash))
            }
        }
    }

    public func onUserInfoUpdate(userInfo: UserInfo) {
        self.currentUserInfo = userInfo
        self.getUserInfoIfNeeded {
            GlobalLogger.shared.debug("APIManager - userInfo request because update")
        }
    }
}
