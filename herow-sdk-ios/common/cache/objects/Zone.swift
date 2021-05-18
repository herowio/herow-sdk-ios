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

public enum LeafType: Int {
    case root = 0
    case leftUp = 1
    case rightUp = 2
    case leftBottom = 3
    case rightBottom = 4
}
public protocol QuadTreeNode {
    func getTreeId() -> String
    func getLocations() -> [QuadTreeLocation]
    func getLeftUpChild() -> QuadTreeNode?
    func getRightUpChild() -> QuadTreeNode?
    func getRightBottomChild() -> QuadTreeNode?
    func getLeftBottomChild() -> QuadTreeNode?
    func getTags() -> [String: Double]?
    func computeTags() 
    func getRect() -> Rect
    func nodeForLocation(_ location: QuadTreeLocation) -> QuadTreeNode?
    func  browseTree(_ location: QuadTreeLocation) -> QuadTreeNode?
    func getReccursiveRects(_ rects: [NodeDescription]?) -> [NodeDescription]
    init(id:String, locations:[QuadTreeLocation]?, leftUp: QuadTreeNode?, rightUp: QuadTreeNode?, leftBottom: QuadTreeNode?, rightBottom: QuadTreeNode?, tags: [String: Double]?, rect: Rect)
    func childs() -> [QuadTreeNode]
    func addLocation(_ location: QuadTreeLocation) -> QuadTreeNode? 
}

public protocol QuadTreeLocation {
    var lat: Double {get set}
    var lng: Double {get set}
    var time: Date {get set}

    init(lat: Double, lng: Double, time: Date)
}

