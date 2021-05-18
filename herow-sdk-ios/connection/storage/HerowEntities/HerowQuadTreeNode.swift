//
//  HerowQuadTreeNode.swift
//  herow_sdk_ios
//
//  Created by Damien on 14/05/2021.
//

import Foundation
import CoreLocation
enum LivingTag: String {
    case home
    case work
    case shopping
}




public struct Rect {
    var originLat: Double
    var endLat: Double
    var originLng: Double
    var endLng: Double

    static let world = Rect(originLat: HerowQuadTreeNode.minLat, endLat: HerowQuadTreeNode.maxLat, originLng: HerowQuadTreeNode.minLng, endLng: HerowQuadTreeNode.maxLng)

    func contains(_ location: QuadTreeLocation) -> Bool {
        let lat = location.lat
        let lng = location.lng
        return originLat <= lat && endLat >= lat && originLng <= lng && endLng >= lng
    }


   public func points() -> [CLLocationCoordinate2D] {
        return [CLLocationCoordinate2D(latitude: originLat, longitude: originLng),
                CLLocationCoordinate2D(latitude: originLat, longitude: endLng),
                CLLocationCoordinate2D(latitude: endLat, longitude: endLng),
                CLLocationCoordinate2D(latitude: endLat, longitude: originLng),
                CLLocationCoordinate2D(latitude: originLat, longitude: originLng)
        ]
    }
    private func middleLat() -> Double {
        return (endLat + originLat) / 2
    }

    private func middleLng() -> Double {
        return (endLng + originLng) / 2
    }
    func leftUpRect() -> Rect {
        return Rect(originLat: middleLat(), endLat: endLat, originLng: originLng, endLng: middleLng())
    }
    func rightUpRect() -> Rect {
        return Rect(originLat: middleLat(), endLat: endLat, originLng: middleLng(), endLng: endLng)
    }

    func leftBottomRect() -> Rect {
        return Rect(originLat: originLat, endLat: middleLat(), originLng: originLng, endLng: middleLng())
    }

    func rigthBottomRect() -> Rect {
        return Rect(originLat: originLat, endLat:  middleLat(), originLng: middleLng(), endLng: endLng)
    }

    func rectForType(_ type: LeafType) -> Rect {
        switch type {
        case .rightUp:
            return rightUpRect()
        case .rightBottom:
            return rigthBottomRect()
        case .leftUp:
            return leftUpRect()
        case .leftBottom:
            return leftBottomRect()
        default:
            return self
        }
    }

    func isMin() -> Bool {
        return CLLocation(latitude: originLat, longitude: originLng).distance(from: CLLocation(latitude: endLat, longitude: endLng)) <= HerowQuadTreeNode.nodeSize
    }
}

public struct NodeDescription {
   public var rect: Rect
    public  var locations:  [QuadTreeLocation]
    public var tags : [String: Double]?
}

class HerowQuadTreeNode: QuadTreeNode {

    static let maxLat = 90.0
    static let minLat = -90.0
    static let maxLng = 180.0
    static let minLng = -180.0
    static let nodeSize = 100.0
    static let locationsLimitCount = 5
    static let fixedLimitLevelCount = 5

    private var rect: Rect =  Rect.world
    private var treeId: String?
    private var locations : [QuadTreeLocation]
    private var rightUpChild : QuadTreeNode?
    private var parentNode : QuadTreeNode?
    private var leftUpChild : QuadTreeNode?
    private var rightBottomChild : QuadTreeNode?
    private var leftBottomChild : QuadTreeNode?
    private var tags: [String: Double]?


    required init(id: String, locations: [QuadTreeLocation]?, leftUp: QuadTreeNode?, rightUp: QuadTreeNode?, leftBottom : QuadTreeNode?, rightBottom : QuadTreeNode?, tags: [String: Double]?, rect: Rect) {
        treeId = id
        self.locations = locations ?? [QuadTreeLocation]()
        rightUpChild = rightUp
        leftUpChild = leftUp
        rightBottomChild = rightBottom
        leftBottomChild = leftBottom
        self.rect = rect
        self.tags = tags
    }

    func getRect() -> Rect {
        return rect
    }
    func getTreeId() -> String {
        return treeId ?? "0"
    }


    func getLocations() -> [QuadTreeLocation] {
        return locations
    }

    func getLeftUpChild() -> QuadTreeNode? {
        return leftUpChild
    }

    func getRightUpChild() -> QuadTreeNode? {
        return rightUpChild
    }

    func getRightBottomChild() -> QuadTreeNode? {
        return rightBottomChild
    }

    func getLeftBottomChild() -> QuadTreeNode? {
        return leftBottomChild
    }

    func getTags() -> [String : Double]? {
        return tags
    }

    func computeTags() {
        var tags =  self.tags ?? [String: Double] ()
        tags[LivingTag.home.rawValue] = scoreForHome()
        tags[LivingTag.work.rawValue] = scoreForWork()
        self.tags = tags
    }

    func scoreForHome() -> Double {
        return 0.0
    }

    func scoreForWork() -> Double {
        return 0.0
    }

    func childs() -> [QuadTreeNode] {
        return [leftUpChild, leftBottomChild, rightUpChild, rightBottomChild].compactMap{$0}
    }

    func hasChildForLocation(_ location : QuadTreeLocation) -> Bool {
        if childForLocation(location) == nil {
            return false
        }
        return true
    }

    func childForLocation(_ location : QuadTreeLocation) -> QuadTreeNode? {
        var result = false
        for child in childs() {
            result = child.getRect().contains(location)
            if result {
                return child
            }
        }
        return nil
    }

    @discardableResult
    func  browseTree(_ location: QuadTreeLocation) -> QuadTreeNode? {
        if rect.contains(location) {
            var nodeResult: QuadTreeNode? = self
            for child in childs() {
                if child.getRect().contains(location ){
                    nodeResult =  child.browseTree(location)
                    if nodeResult != nil {
                        return  nodeResult?.nodeForLocation(location)
                    }
                }
            }
            return nodeResult?.nodeForLocation(location)
        } else {
            return nil
        }
    }

    func getDescription() ->NodeDescription {
        return NodeDescription(rect: getRect(), locations: locations, tags: tags)
    }

    func getReccursiveRects(_ rects: [NodeDescription]? = nil) -> [NodeDescription] {
        var result =  [getDescription()]
        for child in childs() {
            result.append(contentsOf: child.getReccursiveRects(result))
        }
        return result
    }

    func nodeForLocation(_ location: QuadTreeLocation) -> QuadTreeNode? {
        if !rect.contains(location) {
            return nil
        }
        let result =  addLocation(location)
        result?.computeTags()
        return result
    }

   private func limit(_ level : Int) -> Int {
    if (level < HerowQuadTreeNode.fixedLimitLevelCount) {return 1}
        return max( 1, HerowQuadTreeNode.locationsLimitCount  + limit(level - 1 ) )
    }

    func getLimit() -> Int {
        let level = (self.treeId?.count ?? 1) - 1
        let result =  limit(level)
        return  max(1,result - 1)
    }


    @discardableResult
    func splitNode(_ newLocation: QuadTreeLocation) -> QuadTreeNode? {
        dispatchParentLocations()
        if let child = childForLocation(newLocation){
           _ = child.addLocation(newLocation)
            return child
        } else {
            return createChildforLocation(newLocation)
        }
    }

    func locationIsPresent(_ location: QuadTreeLocation) -> Bool {
     return   locations.filter {
            ( location.lat == $0.lat && location.lng == $0.lng && location.time == $0.time)
        }.count >= 1
    }

    func dispatchParentLocations() {
        for location in locations {
            var  child =  childForLocation(location)
            locations = locations.filter {
                !( location.lat == $0.lat && location.lng == $0.lng && location.time == $0.time)
            }
            if child == nil {
                child = createChildforLocation(location)
            } else {
              _ = child?.addLocation(location)
            }
        }
    }

    @discardableResult
    func addLocation(_ location: QuadTreeLocation) -> QuadTreeNode? {
        let count = self.locations.count
        if ((count <= getLimit() && !hasChildForLocation(location)) || rect.isMin()) {
            if !locationIsPresent(location) {
                print ("addLocation node: \(treeId!) count: \(count) isMin? : \( rect.isMin()) limit: \(getLimit())")
                locations.append(location)
            }
            return self
        } else {
          return  splitNode(location)
        }
    }

    func createChildforType(_ type: LeafType, location: QuadTreeLocation?) ->  QuadTreeNode? {
        let treeId  = getTreeId() + "\(type.rawValue)"
        var array =  [QuadTreeLocation]()
        if let location = location {
            array.append(location)
        }
        let child =  HerowQuadTreeNode(id: treeId, locations: array, leftUp: nil, rightUp: nil, leftBottom: nil, rightBottom: nil, tags: [String: Double](), rect: getRect().rectForType(type))
        switch type {
        case .rightUp:
             rightUpChild = child
        case .rightBottom:
          rightBottomChild = child
        case .leftUp:
             leftUpChild = child
        case .leftBottom:
             leftBottomChild = child
        default:
            fatalError("should never append")
        }
        return child
    }

    @discardableResult
    func createChildforLocation(_ location: QuadTreeLocation) ->  QuadTreeNode? {
        let type = leafTypeForLocation(location)
        return  createChildforType(type, location: location)
    }

    func leafTypeForLocation(_ location : QuadTreeLocation) -> LeafType {
        if getRect().leftUpRect().contains(location) {
            return .leftUp
        }
        if getRect().leftBottomRect().contains(location) {
            return .leftBottom
        }
        if getRect().rightUpRect().contains(location){
            return .rightUp
        }
        return .rightBottom
    }
}

struct HerowQuadTreeLocation: QuadTreeLocation {
    var lat: Double
    var lng: Double
    var time: Date
}
