//
//  APIModels.swift
//  herow-sdk-ios
//
//  Created by Damien on 19/01/2021.
//

import Foundation

enum Platform {
    case prod
    case preprod
    var credentials: SDKCredential {
        return SDKCredential(self)
    }
}

public struct ConnectionInfo {
    var platform = Platform.prod
    mutating func updatePlateform(_ platform: String) {
        switch platform {
        case "preprod":
            self.platform = Platform.preprod
        default:
            self.platform = Platform.prod
        }
    }

    public func getUrlType() -> URLType {
        var urlType: URLType = .prod
        switch self.platform {
        case .preprod:
            urlType = .preprod
        case .prod:
            urlType = .preprod
        }
        return urlType
    }
}

public  class SDKCredential {

    let clientId: String
    let clientSecret: String
    let redirectURI: String

    init(_ platform:Platform) {
        let bundle = Bundle(for: Self.self)
            if let path = bundle.path(forResource: "platform-secrets", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path) as? [String: [String:String]]  {
            var platformKey = ""
            switch platform {
            case .preprod:
                platformKey = "preprod"
            default:
                platformKey = "prod"
            }
            clientId = dict[platformKey]?["client_id"] ?? ""
            clientSecret = dict[platformKey]?["client_secret"] ?? ""
            redirectURI = dict[platformKey]?["redirect_uri"] ?? ""
        } else {
            clientId =  ""
            clientSecret = ""
            redirectURI = ""
        }
    }
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
        guard let data = try? decoder.decode(APIUserInfo.self, from: data) else {
            return nil
        }
        return data
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
    var herowId: String?
    var customId: String?
    var lang: String
    var offset: Int = 3600000
    var optins: [Optin]
}

public struct Optin: Codable {
    var type: String
    var value: Bool
    static var optinDataOk = Optin(type: "USER_DATA", value: true)
    static var optinDataNotOk = Optin(type: "USER_DATA", value: false)

    public func encode() -> Data? {
        let encoder = JSONEncoder()
        return try? encoder.encode(self)
    }

    static public func decode(data: Data) -> Optin? {
        let decoder = JSONDecoder()
        guard let token = try? decoder.decode(Optin.self, from: data) else {
            return nil
        }
        return token
    }
}

public struct APICache: Codable {
    var zones: [APIZone]
    var campaigns: [APICampaign]?
    var pois: [APIPoi]?

}

struct NoReply: Codable {
    var response = "OK"
}
