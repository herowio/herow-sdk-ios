//
//  HerowPoi.swift
//  herow-sdk-ios
//
//  Created by Damien on 25/01/2021.
//

import Foundation

public struct HerowPoi: Poi{


    var id: String
    var tags: [String]
    var lat: Double
    var lng: Double

    public init(id: String, tags: [String],lat: Double, lng: Double) {
        self.id = id
        self.lat = lat
        self.lng = lng
        self.tags = tags
    }


   public func getId() -> String {
        return id
    }

    public  func getTags() -> [String] {
        return tags
    }

    public func getLat() -> Double {
        return lat
    }

    public func getLng() -> Double {
        return lng
    }

    public func isValid() -> Bool {
        return true // to do return validity according opening hours
    }
}
