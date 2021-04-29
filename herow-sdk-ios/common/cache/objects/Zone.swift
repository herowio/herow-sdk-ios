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

    init( hash: String, lat: Double, lng: Double, radius: Double, campaigns: [String], access: Access?)

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
    func getName() -> String
    func getBegin() -> Double
    func getEnd() -> Double?
    func getCappings() -> [String: Int]?
    func getNotification() -> Notification?
    func getDaysRecurrence() -> [String]?
    func getStartHour() -> String?
    func getStopHour() -> String?


    init(id: String,
         name: String,
         begin: Double,
         end: Double?,
         cappings: [String: Int]?,
         daysRecurrence: [String],
         notification: Notification?, startHour: String?, stopHour: String?)
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
