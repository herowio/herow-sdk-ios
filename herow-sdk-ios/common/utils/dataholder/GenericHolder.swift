//
//  GenericHolder.swift
//  ConnectPlaceCommon
//
//  Created by Ludovic Vimont on 13/12/2018.
//  Copyright © 2018 Connecthings. All rights reserved.
//

import Foundation

@objc public protocol GenericHolder {
    /**
     * apply any pending updates
     */
    func apply()

    /**
     * Remove all the properties
     */
    func clear()
}
