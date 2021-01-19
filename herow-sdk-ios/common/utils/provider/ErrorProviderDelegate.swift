//
//  ErrorProviderDelegate.swift
//  ConnectPlaceCommon
//
//  Created by Connecthings on 10/04/2018.
//  Copyright © 2018 Connecthings. All rights reserved.
//

import Foundation

public protocol ErrorProviderDelegate: class {

    func onProviderError(source: String,
                         errorCode: Int,
                         errorDesc: NSString,
                         places: [Place],
                         errorInfo: String,
                         requestTime: Double)
}
