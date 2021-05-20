//
//  HerowConstantss.swift
//  herow-sdk-ios
//
//  Created by Damien on 19/01/2021.
//

import Foundation

class HerowConstants {
    static let tokenKey: String = "com.herow.sdk.connection.token"
    static let userInfoKey: String = "com.herow.sdk.connection.userInfo"
    static let userDataOptin: String = "com.herow.sdk.connection.optin"
    static let userInfoStatusKey: String = "com.herow.sdk.connection.userInfo.status"
    static let cacheDateKey: String = "com.herow.sdk.connection.cache.date"
    static let configKey: String = "com.herow.sdk.connection.config"
    static let configDateKey: String = "com.herow.sdk.connection.config.date"
    static let geoHashKey: String = "com.herow.sdk.connection.cache.geoHash"
    static let lastCacheModifiedDateKey: String = "com.herow.sdk.connection.cache.lastModifiedDate"
    static let lastCacheFetchDateKey: String = "com.herow.sdk.connection.cache.fetchDate"
    static let customIdKey: String = "com.herow.sdk.user.customid"
    static let idfvKey: String = "com.herow.sdk.user.idfv"
    static let idfaKey: String = "com.herow.sdk.user.idfa"
    static let herowIdKey: String = "com.herow.sdk.user.herowid"
    static let langKey: String = "com.herow.sdk.user.lang"
    static let utcOffsetKey: String = "com.herow.sdk.user.utc.offset"
    static let herowIdStatusKey: String = "com.herow.sdk.user.herowid.status"
    static let locationStatusKey: String = "com.herow.sdk.user.location.status"
    static let accuracyStatusKey: String = "com.herow.sdk.user.accuracy.status"
    static let notificationStatusKey: String = "com.herow.sdk.user.notification.status"
    static let userDefaultsName: String = "com.herow.sdk.userDefaultsName"

    static let liveMomentSavingDate: String = "com.herow.sdk.liveMomentSavingDate"
}

public struct Headers {
    // swiftlint:disable nesting
    public struct Values {
        public static let contentTypeFormUrlEncoded = "application/x-www-form-urlencoded"
        public static let contentTypeJson = "application/json"
        public static let charsetUtf8="UTF-8"
        public static let gzip="gzip"
    }

    public static let charset: String="Charset"
    public static let contentType: String = "Content-Type"
    public static let contentLength: String = "Content-Length"
    public static let ifModifiedSince = "If-Modified-Since"
    public static let contentEncoding = "Content-Encoding"
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
    static let clientId = "clientId"
    static let clientSecret = "clientSecret"
    static let redirectUri = "redirectUri"
    static let grantType = "grantType"
    static let username = "username"
    static let code = "code"
    static let password: String = "password"
}
