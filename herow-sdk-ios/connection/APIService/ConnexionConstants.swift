//
//  ConnexionConstants.swift
//  herow-sdk-ios
//
//  Created by Damien on 19/01/2021.
//

import Foundation

class ConnexionConstant {
    static let tokenKey: String = "TOKEN_KEY"
    static let userInfoKey: String = "USERINFO_KEY"
    static let configKey: String = "CONFIG_KEY"
    static let configDateKey: String = "CONFIG_DATE_KEY"
}

public struct Headers {
    // swiftlint:disable nesting
    public struct Values {
        public static let contentTypeFormUrlEncoded = "application/x-www-form-urlencoded"
        public static let contentTypeJson = "application/json"
        public static let charsetUtf8="UTF-8"
    }

    public static let charset: String="Charset"
    public static let contentType: String = "Content-Type"
    public static let contentLength: String = "Content-Length"
    public static let ifModifiedSince = "If-Modified-Since"

    public static let authorization: String = "Authorization"
    public static let sdk = "X-SDK"
    public static let version = "X-VERSION"
    public static let deviceId = "X-DEVICE-ID"
    public static let herowId = "X-HEROW-ID"
    public static let userId = "X-USER-ID"
    public static let userAgent = "User-Agent"
    public static let refDate = "X-Ref-Date"
    public static let lastTimeCacheModified = "X-Cache-Last-Modified"
}

struct DateFormat {
    static let universal: String = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
    /*
     * @see: https://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.29
     */
    static let lastModifiedDateFormat: String = "EEE, dd MMM yyyy HH:mm:ss zzz"
}

struct Parameters {
    static let clientId = "client_id"
    static let clientSecret = "client_secret"
    static let redirectUri = "redirect_uri"
    static let grantType = "grant_type"
    static let username = "username"
    static let code = "code"
    static let password: String = "password"
}
