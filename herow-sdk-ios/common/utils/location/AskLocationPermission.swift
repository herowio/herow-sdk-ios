//
//  AskLocationPermission.swift
//  ConnectPlaceCommon
//
//  Created by Connecthings on 10/01/2018.
//  Copyright © 2018 Connecthings. All rights reserved.
//

import Foundation
import CoreLocation

public class AskLocationPermission {

    public static func askPermissionAtStart(locationManager: CLLocationManager) {
        // TODO: find we can't use AskLocationPermission ==> Akward issue /!\/!\/!\
        let bundle = Bundle(for: TimeProviderRelative.self)
        if let content = FileUtils.loadPlist(bundle) {
            if let askLocationPermissionAtStart = content.object(forKey: "askLocationPermissionAtStart") as? Bool {
                if askLocationPermissionAtStart {
                    locationManager.requestAlwaysAuthorization()
                }
            }
        }
    }

}
