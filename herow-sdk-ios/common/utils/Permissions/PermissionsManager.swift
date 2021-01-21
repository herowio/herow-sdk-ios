//
//  PermissionsManager.swift
//  herow-sdk-ios
//
//  Created by Damien on 21/01/2021.
//

import Foundation
import CoreLocation
import AppTrackingTransparency
@objc class PermissionsManager: NSObject  {
    let userInfoManager: UserInfoManagerProtocol
    let dataHolder: DataHolder

     init(userInfoManager: UserInfoManagerProtocol, dataHolder: DataHolder ) {
        self.userInfoManager = userInfoManager
        self.dataHolder = dataHolder
    }

    func requestIDFA(completion: (()->())? = nil) {
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization(completionHandler: { status in

             })
        } else {
            // Fallback on earlier versions
        }
    }

}
