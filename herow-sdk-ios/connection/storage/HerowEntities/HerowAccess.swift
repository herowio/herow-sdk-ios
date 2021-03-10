//
//  HerowAccess.swift
//  herow-sdk-ios
//
//  Created by Damien on 25/01/2021.
//

import Foundation

@objc public class HerowAccess: NSObject, Access, Codable {
    var  id: String
    var  name: String
    var  address: String

   public func getId() -> String {
        return id
    }

    public func getName() -> String {
        return name
    }
    public func getAddress() -> String {
        return address
    }

    required public init(id: String, name: String, address: String) {
        self.id = id
        self.name = name
        self.address = address
    }
}
