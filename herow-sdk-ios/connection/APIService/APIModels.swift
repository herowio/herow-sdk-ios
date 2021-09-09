//
//  APIModels.swift
//  herow-sdk-ios
//
//  Created by Damien on 19/01/2021.
//

import Foundation

public enum Platform {
    case prod
    case preprod
    case test
    var credentials: SDKCredential {
        return SDKCredential(self)
    }
}
// visible objectiv C
@objc public enum HerowPlatform: Int, Codable{

        case prod
        case preprod
        case test

    enum Key: CodingKey {
        case rawValue
    }

    enum CodingError: Error {
        case unknownValue
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        let rawValue = try container.decode(Int.self, forKey: .rawValue)
        switch rawValue {
        case HerowPlatform.prod.rawValue:
            self = .prod
        case HerowPlatform.preprod.rawValue:
            self = .preprod
        case HerowPlatform.test.rawValue:
            self = .test

        default:
            throw CodingError.unknownValue
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Key.self)
        switch self {
        case .prod:
            try container.encode(HerowPlatform.prod.rawValue, forKey: .rawValue)
        case .preprod:
            try container.encode(HerowPlatform.preprod.rawValue, forKey: .rawValue)
        case .test:
            try container.encode(HerowPlatform.test.rawValue, forKey: .rawValue)

        }
    }
}




public protocol ConnectionInfoProtocol {
    var platform: Platform {get set}
    func getUrlType() -> URLType
    mutating func updatePlateform(_ platform: HerowPlatform)
}

public struct ConnectionInfo: ConnectionInfoProtocol {
    public var platform = Platform.prod
    mutating public func updatePlateform(_ platform: HerowPlatform) {
        switch platform {
        case .preprod:
            self.platform = Platform.preprod
        case .test:
            self.platform = Platform.test
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
            urlType = .prod
        case .test:
            urlType = .test
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
