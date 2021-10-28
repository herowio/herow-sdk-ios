//
//  APIPoi.swift
//  herow-sdk-ios
//
//  Created by Damien on 25/01/2021.
//

import Foundation
struct APIPoi: Poi, Codable {
    var id: String
    var tags: [String]
    var lat: Double
    var lng: Double

    enum CodingKeys: String, CodingKey {
        case id
        case lat
        case lng
        case tags
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try values.decodeIfPresent(String.self, forKey: .id) ?? "-1"
        self.lat =  try values.decode(Double.self, forKey: .lat)
        self.lng =  try values.decode(Double.self, forKey: .lng)
        self.tags =  try values.decode([String].self, forKey: .tags)
    }

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

    func isValid() -> Bool {
        return true
    }
}
