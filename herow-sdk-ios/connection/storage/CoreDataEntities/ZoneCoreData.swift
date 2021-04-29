//
//  ZoneCoreData.swift
//  herow-sdk-ios
//
//  Created by Damien on 25/01/2021.
//

import Foundation
import CoreData
@objc(ZoneCoreData)
class ZoneCoreData: NSManagedObject {

    @NSManaged var zoneHash: String
    @NSManaged var lat: Double
    @NSManaged var lng: Double
    @NSManaged var radius: Double
    @NSManaged var campaigns : [String]
    @NSManaged var access: AccessCoreData
}

@objc(AccessCoreData)
class AccessCoreData: NSManagedObject {

    @NSManaged var id: String
    @NSManaged var name: String
    @NSManaged var address: String
}

@objc(PoiCoreData)
class PoiCoreData: NSManagedObject {

    @NSManaged var id: String
    @NSManaged var lat: Double
    @NSManaged var lng: Double
    @NSManaged var tags: [String]

}
@objc(CampaignCoreData)
class CampaignCoreData: NSManagedObject {

    @NSManaged var id: String
    @NSManaged var name: String
    @NSManaged var startHour: String
    @NSManaged var stopHour: String
    @NSManaged var begin: Double
    @NSManaged var end: Double
    @NSManaged var cappings: [String: Int]
    @NSManaged var notification: NotificationCoreData
    @NSManaged var daysRecurrence: [String]
}

@objc(NotificationCoreData)
class NotificationCoreData: NSManagedObject {
    @NSManaged var title: String
    @NSManaged var content: String
    @NSManaged var image: String
    @NSManaged var thumbnail: String
    @NSManaged var textToSpeech: String
    @NSManaged var uri: String
}

@objc(CappingCoreData)
class CappingCoreData: NSManagedObject {
    @NSManaged var campaignId: String
    @NSManaged var count: Int64
    @NSManaged var razDate: Date
}


