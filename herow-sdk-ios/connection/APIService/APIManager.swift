//
//  APIManager.swift
//  herow-sdk-ios
//
//  Created by Damien on 19/01/2021.
//

import Foundation

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

protocol APIManagerProtocol {
     func getConfig(completion: ( (APIConfig?, NetworkError?) -> Void)?)
     func getUserInfo(completion: ( (APIUserInfo?, NetworkError?) -> Void)?)
     func getCache(geoHash: String, completion: ( (APICache?, NetworkError?) -> Void)?)
}

public class APIManager: NSObject, APIManagerProtocol {

    let tokenWorker: APIWorker<APIToken>
    let configWorker: APIWorker<APIConfig>
    let userInfogWorker: APIWorker<APIUserInfo>
    let cacheWorker: APIWorker<APICache>
    let netWorkDataStorage: NetworkDataStorageProtocol
    private  var connectInfo: ConnectionInfo
    var user: User?
     init(connectInfo: ConnectionInfo, netWorkDataStorage: NetworkDataStorageProtocol) {
        self.netWorkDataStorage = netWorkDataStorage
        self.connectInfo = connectInfo
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
        if self.netWorkDataStorage.tokenIsExpired() {
            GlobalLogger.shared.debug("APIManager - token expired")
            self.getAndSaveToken(completion: {_,_ in
                completion()
            })
        }else {
            GlobalLogger.shared.debug("APIManager - token not expired")
            completion()
        }
    }

    private func getAndSaveToken( completion: @escaping (APIToken?, NetworkError?) -> Void) {
        getToken() { token, error in
            var tempToken = token
            if let token = token {
                self.netWorkDataStorage.saveToken(token)
                tempToken = self.netWorkDataStorage.getToken()
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
        getTokenIfNeeded {
            self.configWorker.headers = RequestHeaderCreator.createHeaders(token: self.netWorkDataStorage.getToken()?.accessToken,herowId: self.netWorkDataStorage.getUserInfo()?.herowId)
            self.configWorker.getData() {
                config, error in
                if let config = config {
                    self.netWorkDataStorage.saveConfig(config)
                }
                GlobalLogger.shared.debug("APIManager - config request: \(String(describing: config)) error: \(String(describing: error))")
                completion?(config, error)
            }
        }
    }

    public func getUserInfo(completion: ( (APIUserInfo?, NetworkError?) -> Void)? = nil) {
        getTokenIfNeeded {
            self.userInfogWorker.headers = RequestHeaderCreator.createHeaders(token: self.netWorkDataStorage.getToken()?.accessToken)
            self.userInfogWorker.putData(param:self.userInfoParam()) { userInfo, error in
                if let userInfo = userInfo {
                    self.netWorkDataStorage.saveUserInfo(userInfo)
                }
                GlobalLogger.shared.debug("APIManager - userInfo request: \(String(describing: userInfo)) error: \(String(describing: error))")
                completion?(userInfo, error)
            }
        }
    }

    public func getCache(geoHash: String, completion: ( (APICache?, NetworkError?) -> Void)?) {
        getTokenIfNeeded {
            self.cacheWorker.headers = RequestHeaderCreator.createHeaders(token:self.netWorkDataStorage.getToken()?.accessToken)
            self.cacheWorker.getData(endPoint: .cache(geoHash)) { cache, error in
                GlobalLogger.shared.debug("APIManager - cache request: \(String(describing: cache)) error: \(String(describing: error))")
                completion?(cache, error)

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
        let optin = Optin(type:"USER_DATA",value: true)
        var result: Data?
        let userInfo = UserInfo(adId:nil, adStatus:false,customId:nil,lang: "eng",offset:3600,optins:[optin])
        let encoder = JSONEncoder()

        do {
            result = try encoder.encode(userInfo)

        } catch {
            print("error while encoding userInfo : \(error.localizedDescription)")
        }
        return result
    }
}
