//
//  APINotification.swift
//  herow-sdk-ios
//
//  Created by Damien on 25/01/2021.
//

import Foundation

public struct APINotification: Codable, Notification {
    var title: String
    var description: String
    var image: String?
    var thumbnail: String?
    
    public func getTitle() -> String {
        return title
    }

    public func getDescription() -> String {
        return description
    }

    public init(title: String, description: String, image: String?, thumbnail: String?) {
        self.title = title
        self.description = description
        self.image = image
        self.thumbnail = thumbnail
    }

    public func getImage() -> String? {
        return image
    }
    public func getThumbnail() -> String? {
        return thumbnail
    }

    public init(title: String, description: String) {
        self.title = title
        self.description = description
    }

    enum CodingKeys: String, CodingKey {
        case title
        case description
        case image
        case thumbnail
    }

    public  init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.title = try values.decode(String.self, forKey: .title)
        self.description = try values.decode(String.self, forKey: .description)
        self.image = try values.decodeIfPresent(String.self, forKey: .image)
        self.thumbnail = try values.decodeIfPresent(String.self, forKey: .thumbnail)
    }

}
