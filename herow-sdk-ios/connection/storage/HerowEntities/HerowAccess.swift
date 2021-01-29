//
//  HerowAccess.swift
//  herow-sdk-ios
//
//  Created by Damien on 25/01/2021.
//

import Foundation

public struct HerowAccess: Access, Codable {
    var  id: String
    var  name: String
    var  address: String

    func getId() -> String {
        return id
    }

    func getName() -> String {
        return name
    }
    func getAddress() -> String {
        return address
    }

    init(id: String, name: String, address: String) {
        self.id = id
        self.name = name
        self.address = address
    }
}
