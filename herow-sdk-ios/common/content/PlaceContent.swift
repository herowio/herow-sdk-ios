//
//  PlaceContent.swift
//  ConnectPlaceCommon
//
//  Created by Connecthings on 05/01/2018.
//  Copyright © 2018 Connecthings. All rights reserved.
//

import Foundation

@objc public protocol PlaceContent: AnyObject {

    /// To get the id of the place - must return the same id than the one of the Place class
    ///
    /// - Returns: the id of the place associated to the content
    func getPlaceId() -> NSString

    func getUniqId() -> NSString

    func duplicate() -> PlaceContent?

}
