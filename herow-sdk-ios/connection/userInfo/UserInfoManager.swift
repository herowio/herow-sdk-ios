//
//  UserInfoManager.swift
//  herow-sdk-ios
//
//  Created by Damien on 20/01/2021.
//

import Foundation

class UserInfoManager: UserInfoManagerProtocol {
    static let customIdKey: String = "com.herow.sdk.user.customid"
    static let pushIdKey: String = "com.herow.sdk.user.pushid"
    static let synchroKey: String = "com.herow.sdk.user.synchro"
    static let idfvKey: String = "com.herow.sdk.user.idfv"
    static let idfaKey: String = "com.herow.sdk.user.idfa"
    static let herowIdKey: String = "com.herow.sdk.user.herowid"
    static let langKey: String = "com.herow.sdk.user.lang"
    static let utcOffsetKey: String = "com.herow.sdk.user.utc.offset"
    static let herowIdStatusKey: String = "com.herow.sdk.user.herowid.status"
    static let locationStatusKey: String = "com.herow.sdk.user.location.status"
    static let accuracyStatusKey: String = "com.herow.sdk.user.accuracy.status"
    static let notificationStatusKey: String = "com.herow.sdk.user.notification.status"
}
