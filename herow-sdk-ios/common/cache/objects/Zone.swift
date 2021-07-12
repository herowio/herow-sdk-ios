//
//  Zone.swift
//  herow-sdk-ios
//
//  Created by Damien on 25/01/2021.
//

import Foundation
import CoreLocation

protocol Zone: Codable {

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

public protocol Access: Codable {
    
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

public protocol Poi {

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

public enum LeafDirection: String {
    case root = "0"
    case NW = "1"
    case NE = "2"
    case SW = "3"
    case SE = "4"
}
public protocol QuadTreeNode: AnyObject {

    func redraw()
    func findNodeWithId(_ id: String)  -> QuadTreeNode?
    func getTreeId() -> String
    func setParentNode(_ parent: QuadTreeNode?)
    func getParentNode() -> QuadTreeNode?
    func getUpdate() -> Bool
    func setUpdated(_ value: Bool)
    func getPois() -> [Poi]
    func setPois(_ pois: [Poi]?)
    func getLocations() -> [QuadTreeLocation]
    func allLocations() -> [QuadTreeLocation]
    func getLastLocation() -> QuadTreeLocation?
    func getLeftUpChild() -> QuadTreeNode?
    func getRightUpChild() -> QuadTreeNode?
    func getRightBottomChild() -> QuadTreeNode?
    func getLeftBottomChild() -> QuadTreeNode?
    func getTags() -> [String: Double]?
    func getDensities() -> [String: Double]?
    func computeTags(_ computeParent: Bool)
    func setRect(_ rect: Rect)
    func getRect() -> Rect
    func nodeForLocation(_ location: QuadTreeLocation) -> QuadTreeNode?
    func browseTree(_ location: QuadTreeLocation) -> QuadTreeNode?
    func getReccursiveRects(_ rects: [NodeDescription]?) -> [NodeDescription]
    func getReccursiveNodes(_ nodes: [QuadTreeNode]?) -> [QuadTreeNode]
    init(id: String, locations: [QuadTreeLocation]?, leftUp: QuadTreeNode?, rightUp: QuadTreeNode?, leftBottom : QuadTreeNode?, rightBottom : QuadTreeNode?, tags: [String: Double]?, densities:  [String: Double]?, rect: Rect, pois: [Poi]?)
    func childs() -> [QuadTreeNode]
    func addLocation(_ location: QuadTreeLocation) -> QuadTreeNode?
    func printHierarchy()
    func populateParentality()
    func recursiveCompute()
    func isMin() -> Bool
    func isNewBorn() -> Bool
    func setNewBorn(_ value: Bool)
    func walkLeft() -> QuadTreeNode?
    func walkRight() -> QuadTreeNode?
    func walkUp() -> QuadTreeNode?
    func walkDown() -> QuadTreeNode?
    func walkUpLeft() -> QuadTreeNode?
    func walkUpRight() -> QuadTreeNode?
    func walkDownLeft() -> QuadTreeNode?
    func walkDownRight() -> QuadTreeNode?
    func type()-> LeafType
    func neighbourgs() -> [QuadTreeNode]
    func addInList(_ list: [QuadTreeNode]?) ->  [QuadTreeNode]
    func isEqual(_ node: QuadTreeNode) -> Bool 

   
}

public protocol QuadTreeLocation {
    var lat: Double {get set}
    var lng: Double {get set}
    var time: Date {get set}
    func isNearToPoi() -> Bool
    func setIsNearToPoi(_ near: Bool)
    init(lat: Double, lng: Double, time: Date)
}



