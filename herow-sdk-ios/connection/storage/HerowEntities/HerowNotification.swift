//
//  HerowNotification.swift
//  herow-sdk-ios
//
//  Created by Damien on 26/01/2021.
//

import Foundation

struct HerowNotification: Notification {
    
    var title: String
    var description: String
    var image : String?
    var thumbnail : String?
    var textToSpeech: String?
    var uri: String?

    func getTextToSpeech() -> String? {
        return textToSpeech
    }

    func getUri() -> String? {
        return uri
    }

    func getTitle() -> String {
        return title
    }

    func getDescription() -> String {
        return description
    }

    init(title: String, description: String) {
        self.title = title
        self.description = description
    }
    init(title: String, description: String, image: String?, thumbnail: String?, textToSpeech: String?, uri: String?) {
        self.title = title
        self.description = description
        self.image = image
        self.thumbnail = thumbnail
        self.textToSpeech = textToSpeech
        self.uri = uri
    }


    func getImage() -> String? {
        return image
    }
    func getThumbnail() -> String? {
        return thumbnail
    }

}
