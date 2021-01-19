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

public enum EndPoint: String {
    case  token = "/auth/authorize/token"
    case  config = "/v2/sdk/config"
    case  userInfo = "/v2/sdk/userinfo"
}

public class APIManager: NSObject {

    let tokenWorker: APIWorker<APIToken>
    let configWorker: APIWorker<APIConfig>
    let userInfogWorker: APIWorker<APIUSerInfo>
    let dataHolder: DataHolder
    var platform: PlatForm = .prod
    var user: User?

    public init(plateform: String, dataHolder: DataHolder) {

        self.dataHolder = dataHolder
        var urlType: URLType = .prod
        switch plateform {
        case "preprod":
            self.platform = .preprod
            urlType = .preprod
        case "prod":
            self.platform = .prod
        default:
            assertionFailure("bad plateform configuratuion")
        }
        self.tokenWorker = APIWorker<APIToken>(urlType: urlType, endPoint: .token)
        self.configWorker = APIWorker<APIConfig>(urlType: urlType, endPoint: .config)
        self.userInfogWorker = APIWorker<APIUSerInfo>(urlType: urlType, endPoint: .userInfo)
    }

    private func encodeFormParams(dictionary: [String: String]) -> Data {
        var parts: [String] = []
        for (key, value) in dictionary {
            parts.append("\(key)=\(value)")
        }
        let encodeResult = parts.joined(separator: "&")
        return encodeResult.data(using: String.Encoding.utf8)!
    }

    private func tokenIsExpired() -> Bool {
        guard let token = getToken(), let date = token.expirationDate else {
            return true
        }
        return date < Date()
    }

    private func saveToken(_ token: APIToken) {
        var aToken = token
        aToken.expirationDate = Date().addingTimeInterval(TimeInterval(aToken.expiresIn))
        guard let data = aToken.encode() else {
            return
        }
        dataHolder.putData(key: ConnexionConstant.tokenKey, value: data)
        dataHolder.apply()
    }

    private func getToken() -> APIToken? {

        guard let data = dataHolder.getData(key: ConnexionConstant.tokenKey) else {
            return nil
        }
        guard let token = APIToken.decode(data: data)  else {
            return nil
        }
        return token
    }

    public func getAndSaveToken( completion: @escaping (APIToken?, NetworkError?) -> Void) {
        getToken() { token, error in
            var tempToken = token
            if let token = token {
                self.saveToken(token)
                tempToken = self.getToken()
            }
            completion(tempToken,error)
        }
    }



    public func getToken(completion: @escaping (APIToken?, NetworkError?) -> Void) {
        guard let user = user  else {
            completion(nil,.invalidInPut)
            return
        }
        let paramDict = ["username": user.login,
                         "password": user.password,
                         "client_id": platform.credentials.clientId,
                         "client_secret": platform.credentials.clientSecret,
                         "redirect_uri": platform.credentials.redirectURI,
                         "grant_type" : "password"]

        

        tokenWorker.postData(param: self.encodeFormParams(dictionary: paramDict), completion: completion)

    }

    public func getConfig(completion: @escaping (APIConfig?, NetworkError?) -> Void) {
        configWorker.getData(completion: completion)
    }

    public func getUserInfo(completion: @escaping (APIUSerInfo?, NetworkError?) -> Void) {
        userInfogWorker.putData(completion: completion)
    }




}
