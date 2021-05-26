//
//  HerowQuadTreeNode.swift
//  herow_sdk_ios
//
//  Created by Damien on 14/05/2021.
//

import Foundation
import CoreLocation
public enum LivingTag: String {
    case home
    case work
    case school
    case shopping
}


public struct Circle {
   public var radius: Double
   public var center: CLLocationCoordinate2D

    func area() -> Double {
        return radius * radius * Double.pi
    }
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


    public func circle() -> Circle {
        let radius = CLLocation(latitude: originLat, longitude: originLng).distance(from: CLLocation(latitude: endLat, longitude: endLng)) / 2
        return Circle(radius: radius, center: CLLocationCoordinate2D(latitude: middleLat(), longitude: middleLng()))
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

    func area() -> Double {
        let d1 =  CLLocation(latitude: originLat, longitude: originLng).distance(from: CLLocation(latitude: endLat, longitude: originLng))
        let d2 =  CLLocation(latitude: endLat, longitude: originLng).distance(from: CLLocation(latitude: endLat, longitude: endLng))
        return d1 * d2
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
    public var treeId: String
    public var rect: Rect
    public  var locations:  [QuadTreeLocation]
    public var tags : [String: Double]?
    public var densities : [String: Double]?
    public var isMin: Bool
    public var node: QuadTreeNode


}

class HerowQuadTreeNode: QuadTreeNode {

    static let maxLat = 90.0
    static let minLat = -90.0
    static let maxLng = 180.0
    static let minLng = -180.0
    static let nodeSize = 100.0
    static let locationsLimitCount = 3
    static let fixedLimitLevelCount = 5

    private var rect: Rect =  Rect.world
    private var treeId: String?
    private var locations : [QuadTreeLocation]
    private var rightUpChild : QuadTreeNode?
    private weak var parentNode : QuadTreeNode?
    private var leftUpChild : QuadTreeNode?
    private var rightBottomChild : QuadTreeNode?
    private var leftBottomChild : QuadTreeNode?
    private var tags: [String: Double]?
    private var densities : [String: Double]?
    private var pois: [Poi]?
    private var lastLocation: QuadTreeLocation?
    required init(id: String, locations: [QuadTreeLocation]?, leftUp: QuadTreeNode?, rightUp: QuadTreeNode?, leftBottom : QuadTreeNode?, rightBottom : QuadTreeNode?, tags: [String: Double]?, densities:  [String: Double]?, rect: Rect, pois: [Poi]?) {
        treeId = id
        self.locations = locations ?? [QuadTreeLocation]()
        rightUpChild = rightUp
        leftUpChild = leftUp
        rightBottomChild = rightBottom
        leftBottomChild = leftBottom
        self.rect = rect
        self.tags = tags
        self.densities = densities
        self.pois = pois
     
    }

    func findNodeWithId(_ id: String)  -> QuadTreeNode? {
        let mytreeId = treeId ?? "0"

        if mytreeId == id {
            return self
        } else {
            var childResult: QuadTreeNode?
            for child in childs() {
                childResult = child.findNodeWithId(id)
                if childResult != nil {
                    return childResult
                }
            }
            return nil
        }
    }


    func redraw() {
        self.leftBottomChild?.setRect( getRect().leftBottomRect())
        self.rightBottomChild?.setRect( getRect().rigthBottomRect())
        self.leftUpChild?.setRect( getRect().leftUpRect())
        self.getRightUpChild()?.setRect( getRect().rightUpRect())

        for child in childs() {
            child.redraw()
        }
    }
    func setParentNode(_ parent: QuadTreeNode?) {
        self.parentNode = parent
    }
    func getParentNode() -> QuadTreeNode? {
        return parentNode
    }
    func setRect(_ rect : Rect) {
        self.rect = rect
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

    func getLastLocation() -> QuadTreeLocation? {
        return lastLocation
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
    
    func getDensities() -> [String : Double]? {
        return densities
    }

    func computeTags(_ computeParent: Bool = true) {
        if (treeId?.count ?? 0) < 13 {
            return
        }
        let allLocations = allLocations()
        var tags =  self.tags ?? [String: Double] ()
        var densities =  self.densities ?? [String: Double] ()
        tags[LivingTag.home.rawValue] = 0.0
        tags[LivingTag.work.rawValue] = 0.0
        tags[LivingTag.work.rawValue] = 0.0
        tags[LivingTag.shopping.rawValue] = 0.0
        densities[LivingTag.home.rawValue] = 0.0
        densities[LivingTag.school.rawValue] = 0.0
        densities[LivingTag.work.rawValue] = 0.0
        densities[LivingTag.shopping.rawValue] = 0.0

        let schoolCount =  schoolCount(allLocations)
        let homeCount = homeCount(allLocations)
        let workCount = workCount(allLocations)
        let shoppingCount = shoppingCount(allLocations)
        let locationCount = allLocations.count
        let area = getRect().area()
        if schoolCount > 0 {
            tags[LivingTag.school.rawValue] = Double(schoolCount) / Double(locationCount)
            densities[LivingTag.school.rawValue] = area / Double(schoolCount)
        }
        if homeCount > 0 {
            tags[LivingTag.home.rawValue] = Double(homeCount) / Double(locationCount)
            densities[LivingTag.home.rawValue] = area / Double(homeCount)
        }
        if workCount > 0 {
            tags[LivingTag.work.rawValue] = Double(workCount) / Double(locationCount)
            densities[LivingTag.work.rawValue] = area / Double(workCount)
        }
        if shoppingCount > 0 {
            tags[LivingTag.shopping.rawValue] = Double(shoppingCount) / Double(locationCount)
            densities[LivingTag.shopping.rawValue] = area / Double(shoppingCount)
        }
        self.tags = tags
        self.densities = densities
        if computeParent {
            self.parentNode?.computeTags(true)
        }
    }


    func allLocations() -> [QuadTreeLocation] {

        let allDescr = getReccursiveRects()
        return Array(allDescr.map {$0.locations}.joined())
    }


    func schoolCount(_ locations: [QuadTreeLocation]) -> Int {
        return locations.filter {
            return $0.time.isSchoolCompliant()
        }.count
    }

    func homeCount(_ locations: [QuadTreeLocation]) -> Int {
        return allLocations().filter {
            return $0.time.isHomeCompliant()
        }.count
    }

    func workCount(_ locations: [QuadTreeLocation]) -> Int {
        return allLocations().filter {
            return $0.time.isWorkCompliant()
        }.count
    }

    func shoppingCount(_ locations: [QuadTreeLocation]) -> Int {
        var filteredLocations = [QuadTreeLocation]()
        for loc in allLocations() {
            if let pois = self.pois  {
                var poisForlocation = [Poi]()
                for poi in pois {
                    let distance = CLLocation(latitude: poi.getLat(), longitude: poi.getLng()).distance(from: CLLocation(latitude: loc.lat, longitude: loc.lng))
                    if distance < StorageConstants.shoppingMinRadius {
                        poisForlocation.append(poi)
                    }
                }
                loc.setPois( pois: poisForlocation)
                if poisForlocation.count > 0 {
                    filteredLocations.append(loc)
                }
            }
        }
        return filteredLocations.count
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

    func getPois() -> [Poi]? {
        return self.pois
    }

    func setPois(_ pois: [Poi]?) {
        self.pois = pois
    }
    func getDescription() ->NodeDescription {

        return NodeDescription( treeId: treeId ?? "\(LeafType.root.rawValue)", rect: getRect(), locations: locations, tags: tags, densities: densities, isMin: getRect().isMin(), node: self)
    }

    func getReccursiveRects(_ rects: [NodeDescription]? = nil) -> [NodeDescription] {
        var result =  [getDescription()]
        for child in childs() {
            result.append(contentsOf: child.getReccursiveRects(result))
        }
        return result
    }

    func getReccursiveNodes(_ nodes: [QuadTreeNode]? = nil) -> [QuadTreeNode] {
        var result =  nodes ?? [self]
        for child in childs() {
            result.append(contentsOf: child.getReccursiveNodes(result))
        }
        return result
    }


    func nodeForLocation(_ location: QuadTreeLocation) -> QuadTreeNode? {

        if !rect.contains(location) {
            return nil
        }
        let result =  addLocation(location)

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
                lastLocation = location
                computeTags()
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
        let rect = getRect().rectForType(type)
        let pois = self.pois?.filter {
            let loc = HerowQuadTreeLocation(lat: $0.getLat(), lng: $0.getLng(), time: Date())
            return rect.contains(loc)
        }
        let child =  HerowQuadTreeNode(id: treeId, locations: array, leftUp: nil, rightUp: nil, leftBottom: nil, rightBottom: nil, tags: [String: Double](),densities:  [String: Double](), rect: rect, pois: pois)
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

class HerowQuadTreeLocation: QuadTreeLocation {

    func setPois(pois: [Poi]?) {
        self.pois = pois
    }

    required init(lat: Double, lng: Double, time: Date) {
        self.lat = lat
        self.lng = lng
        self.time = time
    }
    required init(lat: Double, lng: Double, time: Date, pois: [Poi]?) {
       self.lat = lat
       self.lng = lng
       self.time = time
       self.pois = pois
   }

    var lat: Double
    var lng: Double
    var time: Date
    var pois: [Poi]?
}
