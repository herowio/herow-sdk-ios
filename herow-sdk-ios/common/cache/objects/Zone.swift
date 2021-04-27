//
//  Zone.swift
//  herow-sdk-ios
//
//  Created by Damien on 25/01/2021.
//

import Foundation
import CoreLocation
protocol Zone  {

    func getHash() -> String
    func getLat() -> Double
    func getLng() -> Double
    func getRadius() -> Double
    func getCampaigns() -> [String]
    func getAccess() -> Access?
    func getLiveEvent() -> Bool
    init( hash: String, lat: Double, lng: Double, radius: Double, campaigns: [String], access: Access?, liveEvent: Bool)

}

extension Zone {
    func distanceFrom( location: CLLocation) -> CLLocationDistance {
        let center = CLLocation(latitude: getLat(), longitude: getLng())
        return center.distance(from: location)
    }
}

public protocol Access {
    
    func getId() -> String
    func getName() -> String
    func getAddress() -> String
    init(id: String, name: String, address: String)
}

 protocol Campaign {

    func getId() -> String
    func getCompany() -> String
    func getCreatedDate() -> Double
    func getModifiedDate() -> Double
    func getDeleted() -> Bool
    func getName() -> String
    func getSimpleId() -> String
    func getBegin() -> Double
    func getEnd() -> Double?
    func getRealTimeContent() -> Bool
    func getIntervals() -> [Interval]?
    func getTriggers() -> [String: Int]
    func getCappings() -> [String: Int]?
    func getTz() -> String
    func getNotification() -> Notification?
    func getDaysRecurrence() -> [String]?
    func getReccurenceEnable() -> Bool
    func getStartHour() -> String?
    func getStopHour() -> String?


    init(id: String,
         company: String,
         name: String,
         createdDate: Double,
         modifiedDate: Double,
         deleted: Bool,
         simpleId: String,
         begin: Double,
         end: Double?,
         realTimeContent: Bool,
         intervals: [Interval]?,
         cappings: [String: Int]?,
         triggers:[String: Int],
         daysRecurrence: [String],
         recurrenceEnabled:Bool,
         tz:String,
         notification: Notification?, startHour: String?, stopHour: String?)
}

extension Campaign {
    func isExit() -> Bool {
        return getTriggers()["onExit"] == 1
    }

    func isPersistent() -> Bool {
        return getTriggers()["isPersistent"] == 1
    }
}

 protocol Interval {

    func getStart() -> Int64
    func getEnd() -> Int64?
    init(start: Int64, end: Int64)
}

 protocol Notification {

    func getTitle() -> String
    func getDescription() -> String
    init(title: String, description: String)
    init(title: String, description: String, image: String?, thumbnail: String?, textToSpeech: String?, uri: String?)
    func getImage() -> String?
    func getThumbnail() -> String?
    func getTextToSpeech() -> String?
    func getUri() -> String?
}

protocol Poi {

    func getId() -> String
    func getTags() -> [String]
    func getLat() -> Double
    func getLng() -> Double
    init(id: String, tags: [String],lat: Double, lng: Double)
}

public protocol Capping {
    func getId() -> String
    func getRazDate() -> Date
    func getCount() -> Int64
    func setRazDate(date: Date)
    func setCount(count: Int64)
    init(id: String, razDate: Date, count: Int64)
}
