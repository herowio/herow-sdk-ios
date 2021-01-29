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

     init(id: String, tags: [String],lat: Double, lng: Double) {
        self.id = id
        self.lat = lat
        self.lng = lng
        self.tags = tags
    }


    func getId() -> String {
        return id
    }

    func getTags() -> [String] {
        return tags
    }

    func getLat() -> Double {
        return lat
    }

    func getLng() -> Double {
        return lng
    }
}
