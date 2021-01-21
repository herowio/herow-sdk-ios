//
//  APIModels.swift
//  herow-sdk-ios
//
//  Created by Damien on 19/01/2021.
//

import Foundation

enum PlatForm {
    case prod
    case preprod

    var credentials: SDKCredential {
            switch self {
                case .prod:
                    return SDKCredential(clientId: "95634158622", clientSecret: "X33ohuSqX6kjI7ijDa91P4DZJVAmmHZe", redirectURI: "https://m.herow.io")
                case .preprod:
                    return SDKCredential(clientId: "65238409552", clientSecret: "Vq3p1nXx1NQal1di10IfkC4yLsd0KAM6", redirectURI: "https://m-preprod.herow.io")
            }
        }
}



public  struct SDKCredential {

    let clientId: String
    let clientSecret: String
    let redirectURI: String
}

public struct APIConfig: Codable {
    let cacheInterval: Int64
    let configInterval: Int64
    let enabled: Bool

    public func encode() -> Data? {
         let encoder = JSONEncoder()
        return try? encoder.encode(self)
     }
     static public func decode(data: Data) -> APIConfig? {
         let decoder = JSONDecoder()
         guard let token = try? decoder.decode(APIConfig.self, from: data) else {
                 return nil
             }
         return token
     }
}

public struct APIToken: Codable {
    let accessToken: String
    let expiresIn: Int64
    var expirationDate: Date?

   public func encode() -> Data? {
        let encoder = JSONEncoder()
       return try? encoder.encode(self)
    }

    static public func decode(data: Data) -> APIToken? {
        let decoder = JSONDecoder()
        guard let token = try? decoder.decode(APIToken.self, from: data) else {
                return nil
            }
        return token
    }
}

public struct APIUserInfo: Codable {
    let herowId: String
    let modifiedDate: Int64

    public func encode() -> Data? {
        let encoder = JSONEncoder()
        return try? encoder.encode(self)
    }
    
    static public func decode(data: Data) -> APIUserInfo? {
        let decoder = JSONDecoder()
        guard let token = try? decoder.decode(APIUserInfo.self, from: data) else {
            return nil
        }
        return token
    }
}

public struct User {
    let login: String
    let password: String
    public let company: String?
    public init(login: String, password: String, company: String? = nil) {
        self.login = login
        self.password = password
        self.company = company
    }
}

public struct UserInfo: Codable {
    var adId: String?
    var adStatus: Bool
    var customId: String?
    var lang: String
    var offset: Int64 = 3600
    var optins: [Optin]
}

public struct Optin: Codable {
    var type: String
    var value: Bool
}

public struct APICache: Codable {

}



