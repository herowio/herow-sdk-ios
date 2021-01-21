//
//  RequestHeaderCreator.swift
//  herow-sdk-ios
//
//  Created by Damien on 20/01/2021.
//

import Foundation

public class RequestHeaderCreator {
    static func createHeaders(token: String? = nil, herowId: String? = nil) -> [String: String] {
        var hearders = [ Headers.contentType: Headers.Values.contentTypeJson,
                         Headers.version: Bundle(for: Self.self).infoDictionary?["CFBundleVersion"] as? String ?? "0.0.0"]
        if let deviceID = DeviceUtils.deviceID() {
            hearders[Headers.deviceId] = deviceID
        }
        if let token = token {
            hearders[Headers.authorization] = "OAuth \(token)"
        }
        if let herowId = herowId {
            hearders[Headers.herowId] = herowId
        }

        return hearders
    }
}
