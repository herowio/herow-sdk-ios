//
//  Time.swift
//  ConnectPlaceCommon
//
//  Created by Connecthings on 10/07/2017.
//  Copyright © 2017 Connecthings. All rights reserved.
//

import Foundation

@objc public protocol TimeProvider {
    func getTime() -> Double
    func getDate() -> Date
}
