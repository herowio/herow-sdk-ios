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

}
