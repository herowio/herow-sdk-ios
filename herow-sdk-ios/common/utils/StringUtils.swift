//
//  StringUtils.swift
//  ConnectPlaceCommon
//
//  Created by ConnecthingsŒ on 05/10/2017.
//  Copyright © 2017 Connecthings. All rights reserved.
//

import Foundation

public class StringUtils {
    public static func isEmpty(string: String?) -> Bool {
        return string == nil || string == ""
    }

    public static func getDeviceLanguage() -> String {
        if let deviceLang: String = Locale.preferredLanguages.first {
            if let mainLang = deviceLang.components(separatedBy: "-").first {
                return mainLang
            } else {
                return deviceLang
            }
        }
        GlobalLogger.shared.warning("Can't find the device default language")
        return "unknown"
    }
}
