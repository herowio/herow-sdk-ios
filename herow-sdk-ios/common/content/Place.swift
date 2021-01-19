//
//  Place.swift
//  ConnectPlaceProvider
//
//  Created by Connecthings on 04/07/2017.
//  Copyright © 2017 Connecthings. All rights reserved.
//

import Foundation

@objc public protocol Place {

    /// To identify a place - the id make the link with a remote backend or a local DB
    ///
    /// - Returns: the id of the place
    var description: String { get }

    func getId() -> NSString

    func liveEventEnable() -> Bool

}
