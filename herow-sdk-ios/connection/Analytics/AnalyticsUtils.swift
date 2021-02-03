//
//  AnalyticsUtils.swift
//  herow-sdk-ios
//
//  Created by Damien on 01/02/2021.
//

import Foundation
import UIKit 
public class UserAgent {
    let appInfo: BundleInfo
    let deviceInfo: DeviceInfo
    let userDefaults: UserDefaults

    public init(appInfo: BundleInfo, deviceInfo: DeviceInfo, userDefaults: UserDefaults) {
        self.appInfo = appInfo
        self.deviceInfo = deviceInfo
        self.userDefaults = userDefaults
    }

    private func clientUserAgent(prefix: String) -> String {
        var clientUser = "\(prefix)/\(appInfo.version)b\(appInfo.buildNumber) (\(deviceInfo.deviceModel());"
        clientUser += "iPhone OS \(UIDevice.current.systemVersion)) (\(appInfo.displayName))"
        return clientUser
    }

    /**
     * Use this if you know that a value must have been computed before your
     * code runs, or you don't mind failure.
     */
    func cachedUserAgent(checkiOSVersion: Bool = true,
                         checkFirefoxVersion: Bool = true,
                         checkFirefoxBuildNumber: Bool = true) -> String? {
        let currentiOSVersion = UIDevice.current.systemVersion
        let lastiOSVersion = userDefaults.string(forKey: "LastDeviceSystemVersionNumber")
        let currentFirefoxBuildNumber = appInfo.buildNumber
        let currentFirefoxVersion = appInfo.version
        let lastFirefoxVersion = userDefaults.string(forKey: "LastFirefoxVersionNumber")
        let lastFirefoxBuildNumber = userDefaults.string(forKey: "LastFirefoxBuildNumber")
        if let firefoxUA = userDefaults.string(forKey: "UserAgent") {
            if (!checkiOSVersion || (lastiOSVersion == currentiOSVersion))
                && (!checkFirefoxVersion || (lastFirefoxVersion == currentFirefoxVersion)
                    && (!checkFirefoxBuildNumber || (lastFirefoxBuildNumber == currentFirefoxBuildNumber))) {
                return firefoxUA
            }
        }
        return nil
    }

    public func defaultUserAgent() -> String {
        if let firefoxUA = self.cachedUserAgent(checkiOSVersion: true) {
            return firefoxUA
        }
        let appVersion = appInfo.version
        let buildNumber = appInfo.buildNumber
        let currentiOSVersion = UIDevice.current.systemVersion
        userDefaults.set(currentiOSVersion, forKey: "LastDeviceSystemVersionNumber")
        userDefaults.set(appVersion, forKey: "LastFirefoxVersionNumber")
        userDefaults.set(buildNumber, forKey: "LastFirefoxBuildNumber")
        let firefoxUA = "Mozilla/5.0 (\(deviceName()); CPU \(deviceModel()) \(systemVersion()) like Mac OS X) FxiOS/\(appVersion)b\(appInfo.buildNumber)"
        userDefaults.set(firefoxUA, forKey: "UserAgent")
        userDefaults.synchronize()
        return firefoxUA
    }

    func deviceName() -> String {
        var sysinfo = utsname()
        uname(&sysinfo)
        return String(bytes: Data(bytes: &sysinfo.machine, count: Int(_SYS_NAMELEN)), encoding: .ascii)!.trimmingCharacters(in: .controlCharacters)
    }
    //eg. OS 10_1
    func systemVersion() -> String {
        let currentDevice = UIDevice.current
        return "OS \(currentDevice.systemVersion.replacingOccurrences(of: ".", with: "_"))"
    }
    //eg. iPhone
    func deviceModel() -> String {
       return UIDevice.current.model
    }


}

public class DeviceInfo {
    let appInfo: BundleInfo

    public init(appInfo: BundleInfo) {
        self.appInfo = appInfo
    }

    // Return the client name, which can be either "Fennec on Stefan's iPod" or simply "Stefan's iPod" if the
    // application display name cannot be obtained.
    func defaultClientName() -> String {
        var comment = "A brief descriptive name for this app on this device, used for Send Tab and Synced Tabs."
        comment += " The first argument is the app name. The second argument is the device name."
        let format = NSLocalizedString("%@ on %@", tableName: "Shared", comment: comment)
        return String(format: format, appInfo.displayName, UIDevice.current.name)
    }

    func deviceModel() -> String {
        return UIDevice.current.model
    }

    func deviceId() -> String {
        return  UIDevice.current.identifierForVendor?.uuidString ?? ""
    }

    func isSimulator() -> Bool {
        return ProcessInfo.processInfo.environment["SIMULATOR_ROOT"] != nil
    }

    func hasConnectivity() -> Bool {
        let status = Reach().connectionStatus()
        switch status {
        case .online(.wwan):
            return true
        case .online(.wiFi):
            return true
        default:
            return false
        }
    }
}


public class BundleInfo {
    /// Return the main application bundle. If this is called from an extension,
    // the containing app bundle is returned.
    public var bundle: Bundle

    public var displayName: String {
        return bundle.object(forInfoDictionaryKey: kCFBundleNameKey as String) as! String
    }

    public var version: String {
        if let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
            return version
        }
        return ""
    }

    public var buildNumber: String {
        if let number = bundle.object(forInfoDictionaryKey: String(kCFBundleVersionKey)) as? String {
            return number
        }
        return ""
    }

    public var majorAppVersion: String {
        return version.components(separatedBy: ".").first!
    }

    /// Return the base bundle identifier.
    ///
    /// This function is smart enough to find out if it is being called from an extension or the main application. In
    /// case of the former, it will chop off the extension identifier from the bundle since that is a suffix not part
    /// of the *base* bundle identifier.
    public var baseBundleIdentifier: String {
        let packageType = bundle.object(forInfoDictionaryKey: "CFBundlePackageType") as! String
        let baseBundleIdentifier = bundle.bundleIdentifier!
        if packageType == "XPC!" {
            let components = baseBundleIdentifier.components(separatedBy: ".")
            return components[0..<components.count-1].joined(separator: ".")
        }
        return baseBundleIdentifier
    }

    // Return whether the currently executing code is running in an Application
    public var isApplication: Bool {
        return bundle.object(forInfoDictionaryKey: "CFBundlePackageType") as! String == "APPL"
    }

    public init(bundle: Bundle) {
        self.bundle = bundle
    }

    public convenience init() {
        self.init(bundle: Bundle.main)
    }
}

public class AnalyticsInfo {
    public let appInfo: BundleInfo
    public let deviceInfo: DeviceInfo
    public let libInfo: BundleInfo
    public let userAgent: UserAgent


    public init(appBundle: Bundle, libBundle: Bundle, userDefaults: UserDefaults) {
        appInfo = BundleInfo(bundle: appBundle)
        libInfo = BundleInfo(bundle: libBundle)
        deviceInfo = DeviceInfo(appInfo: appInfo)
        userAgent = UserAgent(appInfo: appInfo, deviceInfo: deviceInfo, userDefaults: userDefaults)
    }

    public convenience init() {
        self.init(appBundle: Bundle.main,
                  libBundle: Bundle(for: AnalyticsInfo.self),
                  userDefaults: UserDefaults(suiteName: HerowConstants.userDefaultsName)!
                )
    }

}
