//
//  ErrorProviderInfo.swift
//  ConnectPlaceCommon
//
//  Created by Connecthings on 10/04/2018.
//  Copyright © 2018 Connecthings. All rights reserved.
//

import Foundation

public class ErrorProviderInfo {

    public let status: ProviderStatus
    public let code: Int
    public let description: NSString
    public let errorInfo: NSString

    public init(status: ProviderStatus,
                code: Int,
                description: NSString,
                errorInfo: NSString = "") {
        self.status = status
        self.code = code
        self.description = description
        self.errorInfo = errorInfo
    }

    public convenience init(status: ProviderStatus,
                            code: Int,
                            description: NSString) {
        self.init(status: status,
                  code: code,
                  description: description,
                  errorInfo: "")
    }
}
