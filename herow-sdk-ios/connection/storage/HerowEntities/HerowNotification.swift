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
