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
    @NSManaged var liveEvent: Bool
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
    @NSManaged var company: String
    @NSManaged var createdDate: Double
    @NSManaged var modifiedDate: Double
    @NSManaged override var isDeleted: Bool
    @NSManaged var simpleId: String
    @NSManaged var name: String
    @NSManaged var startHour: String
    @NSManaged var stopHour: String
    @NSManaged var begin: Double
    @NSManaged var end: Double
    @NSManaged var realTimeContent: Bool
    @NSManaged var intervals: Set<IntervalCoreData>
    @NSManaged var cappings: [String: Int]
    @NSManaged var triggers: [String: Int]
    @NSManaged var tz: String
    @NSManaged var notification: NotificationCoreData
    @NSManaged var recurrenceEnabled: Bool
    @NSManaged var daysRecurrence: [String]
}

@objc(IntervalCoreData)
class IntervalCoreData: NSManagedObject {
    @NSManaged var start: Int64
    @NSManaged var end: Int64
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

