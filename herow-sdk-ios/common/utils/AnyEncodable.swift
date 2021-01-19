//
//  AnyEncodable.swift
//  ConnectPlaceCommon
//
//  Created by Connecthings on 15/01/2018.
//  Copyright © 2018 Connecthings. All rights reserved.
//

import Foundation

public struct AnyEncodable: Encodable {
    private let encodable: Encodable

    public init(_ encodable: Encodable) {
        self.encodable = encodable
    }

    public func encode(to encoder: Encoder) throws {
        try encodable.encode(to: encoder)
    }
}
