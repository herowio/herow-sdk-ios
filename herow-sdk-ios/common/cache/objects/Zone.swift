//
//  Zone.swift
//  herow-sdk-ios
//
//  Created by Damien on 25/01/2021.
//

import Foundation
import CoreLocation
import UIKit
public protocol Zone: Zonable, Codable {
    func getCampaigns() -> [String]
    func getAccess() -> Access?
    init( hash: String, lat: Double, lng: Double, radius: Double, campaigns: [String], access: Access?)

}

extension Zone {
    func contains(_ loc: QuadTreeLocation) -> Bool {
        let center = CLLocation(latitude: self.getLat(), longitude: self.getLng())
        let toTest = CLLocation(latitude: loc.lat, longitude: loc.lng)
        return  center.distance(from: toTest) <= self.getRadius()
    }
}

public protocol Zonable {
    func getHash() -> String
    func getLat() -> Double
    func getLng() -> Double
    func getRadius() -> Double
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

public protocol Campaign {

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

public protocol Notification {
    func getTitle() -> String
    func getDescription() -> String
    init(title: String, description: String)
    init(title: String, description: String, image: String?, thumbnail: String?, textToSpeech: String?, uri: String?)
    func getImage() -> String?
    func getThumbnail() -> String?
    func getTextToSpeech() -> String?
    func getUri() -> String?
}

public protocol Poi: Codable {
    func getId() -> String
    func getTags() -> [String]
    func getLat() -> Double
    func getLng() -> Double
    func isValid() -> Bool
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

public  enum NodeType: Int {
    case home = 0
    case work = 1
    case school = 2
    case shop = 3
    case none = 4
}

public protocol QuadTreeNode: AnyObject, Zonable {
    var liveMomentTypes: [NodeType] {get set}
    var merged: Bool {get set}
    var recurencies: [RecurencyDay: Int] { get set}
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
    func setLastLocation(_ location :QuadTreeLocation?)
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
    func neighbours() -> [QuadTreeNode]
    func isNearToPoi() -> Bool
    func addInList(_ list: [QuadTreeNode]?) ->  [QuadTreeNode]
    func isEqual(_ node: QuadTreeNode) -> Bool
    func getLimit() -> Int
    func computeRecurency(_ loc: QuadTreeLocation)



}

struct LiveMomentResult {
    var homes: [QuadTreeNode]
    var works: [QuadTreeNode]
    var schools: [QuadTreeNode]
    var shoppings:  [QuadTreeNode]
}

extension QuadTreeNode {
    public func getCount() -> Int {
        return getLocations().count
    }
    
    func addNodeType(_ type: NodeType) {
        if !self.liveMomentTypes.contains(type) {
        self.liveMomentTypes.append(type)
        }
    }

    func removeNodeType(_ type: NodeType) {
        if self.liveMomentTypes.contains(type) {
            self.liveMomentTypes.removeAll {$0 == type}
        }
    }

    func resetNodeTypes() {
        self.liveMomentTypes.removeAll()
    }

    internal func getLiveMoments() -> LiveMomentResult {
        var homes = [QuadTreeNode]()
        var works = [QuadTreeNode]()
        var schools = [QuadTreeNode]()
        var shoppings = [QuadTreeNode]()
        return self.getLiveMoments(homes: &homes, works: &works, schools: &schools, shoppings: &shoppings)
    }

    @discardableResult
    internal func getLiveMoments(homes: inout [QuadTreeNode] ,
                                 works: inout [QuadTreeNode],
                                 schools: inout [QuadTreeNode],
                                 shoppings: inout [QuadTreeNode]) -> LiveMomentResult {

        if childs().count == 0 {
            if self.liveMomentTypes.contains(.home) {
                homes.append(self)
            }
            if self.liveMomentTypes.contains(.work) {
                works.append(self)
            }
            if self.liveMomentTypes.contains(.school) {
                schools.append(self)
            }
            if self.liveMomentTypes.contains(.shop) {
                shoppings.append(self)
            }
        } else {
            self.childs().forEach {
                $0.getLiveMoments(homes: &homes, works: &works, schools: &schools, shoppings: &shoppings)
            }
        }
        return LiveMomentResult(homes: homes, works: works, schools: schools, shoppings: shoppings)
    }

    func createRecurencies() -> [String: Int64] {
        var recurencies = [String: Int64]()
        for key in self.recurencies.keys {
            let day = key.rawValue()
            let value = self.recurencies[key] ?? 0
            recurencies[day] = Int64(value)
        }
        return recurencies
    }

  public  func getLocationPattern() -> LocationPattern {
      return getRawLocationPattern().filtered()
    }

    public  func getRawLocationPattern() -> LocationPattern {
          let count: Double  = Double(self.getCount())
          var pattern = LocationPattern()
          for (key, value) in self.recurencies {
              pattern[key.rawValue()] = Decimal((Double(value) / count).round(to: 2))
          }
        return pattern
      }

    public func resetRecurrencies() {
        for l in getLocations() {
            let day = l.time.recurencyDay
            var value: Int = self.recurencies[day] ?? 0
            value = value + 1
            self.recurencies[day] = value
        }
    }

}

public protocol QuadTreeLocation {
    var lat: Double {get set}
    var lng: Double {get set}
    var time: Date {get set}
    func isNearToPoi() -> Bool
    func setIsNearToPoi(_ near: Bool)
    init(lat: Double, lng: Double, time: Date)
}

public protocol PeriodProtocol {
    var start: Date {get set}
    var end: Date {get set}
    var workLocations: [QuadTreeLocation] {get set}
    var homeLocations: [QuadTreeLocation] {get set}
    var schoolLocations: [QuadTreeLocation] {get set}
    var otherLocations: [QuadTreeLocation] {get set}
    var poiLocations: [QuadTreeLocation] {get set}
    func getAllLocations() ->  [QuadTreeLocation]
    init(workLocations: [QuadTreeLocation],homeLocations: [QuadTreeLocation],schoolLocations: [QuadTreeLocation],otherLocations: [QuadTreeLocation],poiLocations: [QuadTreeLocation], start: Date, end: Date)
}

public extension PeriodProtocol {
    func containsLoc(_ location: QuadTreeLocation) -> Bool {
        return self.start < location.time && self.end > location.time
    }

    mutating func addLocation(_ location: QuadTreeLocation) {
        if self.containsLoc(location) {
            if location.time.isHomeCompliant() {
                self.homeLocations.append( location)
            }
            else if location.time.isWorkCompliant() {
                self.workLocations.append( location)
            }
            else if location.time.isSchoolCompliant() {
                self.schoolLocations.append( location)
            }
            else  {
                self.otherLocations.append( location)
            }
            if location.isNearToPoi() {
                self.poiLocations.append(location)
            }
        }
    }
}





