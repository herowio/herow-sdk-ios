//
//  RequestHeaderCreator.swift
//  herow-sdk-ios
//
//  Created by Damien on 20/01/2021.
//

import Foundation

public class RequestHeaderCreator {
    static func createHeaders(sdk: String?,token: String? = nil, herowId: String? = nil) -> [String: String] {
        let infos = AnalyticsInfo()
        var hearders = [ Headers.contentType: Headers.Values.contentTypeJson,
                         Headers.version: infos.libInfo.version,
                         Headers.deviceId: infos.deviceInfo.deviceId()
        ]


        if let token = token {
            hearders[Headers.authorization] = "OAuth \(token)"
        }
        if let herowId = herowId {
            hearders[Headers.herowId] = herowId
        }

        if let sdk = sdk {
            hearders[Headers.sdk] = sdk
        }

        return hearders
    }
}
