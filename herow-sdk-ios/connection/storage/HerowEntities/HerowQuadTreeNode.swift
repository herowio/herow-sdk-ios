//
//  HerowQuadTreeNode.swift
//  herow_sdk_ios
//
//  Created by Damien on 14/05/2021.
//

import Foundation
import CoreLocation
import UIKit
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

public struct Rect: Equatable {
    public var originLat: Double
    public var endLat: Double
    public var originLng: Double
    public var endLng: Double

    static let world = Rect(originLat: HerowQuadTreeNode.minLat, endLat: HerowQuadTreeNode.maxLat, originLng: HerowQuadTreeNode.minLng, endLng: HerowQuadTreeNode.maxLng)
    public  init(originLat: Double, endLat: Double, originLng: Double, endLng: Double) {
        self.originLat = originLat
        self.endLat = endLat
        self.originLng = originLng
        self.endLng = endLng
    }
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

   public func isEqual(_ rect: Rect) -> Bool {
        return originLat == rect.originLat && endLat == rect.endLat && originLng == rect.originLng && endLng == rect.endLng
    }

   public func contains(_ rect: Rect) -> Bool {
        return originLat <= rect.originLat && endLat >= rect.endLat && originLng <= rect.originLng && endLng >= rect.endLng && !isEqual(rect)
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
    var merged: Bool = false


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
    private var parentNode : QuadTreeNode?
    private var leftUpChild : QuadTreeNode?
    private var rightBottomChild : QuadTreeNode?
    private var leftBottomChild : QuadTreeNode?
    private var tags: [String: Double]?
    private var densities : [String: Double]?
    private var pois: [Poi]?
    private var lastLocation: QuadTreeLocation?
    private var updated = false 
    private var lastHomeCount: Int = -1
    private var lastWorkCount : Int = -1
    private var lastSchoolCount: Int = -1
    private var newBorn = false

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
        self.setParentality()
    }

    deinit {
        GlobalLogger.shared.debug( "node denit")
        rightUpChild?.setParentNode(nil)
        leftUpChild?.setParentNode(nil)
        rightBottomChild?.setParentNode(nil)
        leftBottomChild?.setParentNode(nil)
    }

    func setParentality() {
        rightUpChild?.setParentNode(self)
        leftUpChild?.setParentNode(self)
        rightBottomChild?.setParentNode(self)
        leftBottomChild?.setParentNode(self)
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

    func recursiveCompute() {
        self.computeTags(false)
        self.updated = true
        for child in childs() {
            child.computeTags(false)
        }
    }

    func isNewBorn() -> Bool {
        return newBorn
    }

    func setNewBorn(_ value: Bool) {
        newBorn = value
    }

    func getUpdate() -> Bool {
        return updated
    }

    func setUpdated(_ value: Bool) {
        updated = value

        if value == false {
            self.childs().forEach { child in
                child.setUpdated(false)
            }
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

    func isMin() -> Bool {
        return rect.isMin()
    }

    func getLocations() -> [QuadTreeLocation] {
        return locations
    }

    func getLastLocation() -> QuadTreeLocation? {
        return lastLocation
    }

    func setLastLocation(_ location :QuadTreeLocation?)  {
         lastLocation = location
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

        let start = CFAbsoluteTimeGetCurrent()
        if(computeParent) {
            GlobalLogger.shared.debug("LiveMomentStore - computeTags start")
        }
        let _allLocations = allLocations()
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


        let _schoolCount =  schoolCount(_allLocations)
        let _homeCount = homeCount(_allLocations)
        let _workCount = workCount(_allLocations)
        let _shoppingCount = shoppingCount(_allLocations)
        let locationCount = _allLocations.count

        let area = getRect().area()
        if _schoolCount > 0 {
            tags[LivingTag.school.rawValue] = Double(_schoolCount) / Double(locationCount)
            densities[LivingTag.school.rawValue] = area / Double(_schoolCount)
        }
        if _homeCount > 0 {
            tags[LivingTag.home.rawValue] = Double(_homeCount) / Double(locationCount)
            densities[LivingTag.home.rawValue] = area / Double(_homeCount)
        }
        if _workCount > 0 {
            tags[LivingTag.work.rawValue] = Double(_workCount) / Double(locationCount)
            densities[LivingTag.work.rawValue] = area / Double(_workCount)
        }
        if _shoppingCount > 0 {
            tags[LivingTag.shopping.rawValue] = Double(_shoppingCount) / Double(locationCount)
            densities[LivingTag.shopping.rawValue] = area / Double(_shoppingCount)
        }
        self.tags = tags
        self.densities = densities
        if computeParent {
            self.parentNode?.computeTags(false)
        }
        let end = CFAbsoluteTimeGetCurrent()
        let elapsedTime = (end - start) * 1000
        if(computeParent) {
            GlobalLogger.shared.debug("LiveMomentStore - computeTags done in \(elapsedTime) ms  ")
        }
    }

    func allLocations() -> [QuadTreeLocation] {

         let allDescr = getReccursiveRects()
         return Array(allDescr.map {$0.locations}.joined())
    }

    func schoolCount(_ locations: [QuadTreeLocation]) -> Int {
        if lastSchoolCount == -1 {
        return locations.filter {
            return $0.time.isSchoolCompliant()
        }.count
        } else {
            if lastLocation?.time.isSchoolCompliant() ?? false {
                lastSchoolCount = lastSchoolCount + 1
            }
            return lastSchoolCount
        }
    }

    func homeCount(_ locations: [QuadTreeLocation]) -> Int {
        if lastHomeCount == -1 {
        return allLocations().filter {
            return $0.time.isHomeCompliant()
        }.count
        } else {
            if lastLocation?.time.isHomeCompliant() ?? false {
                lastHomeCount = lastHomeCount + 1
            }
            return lastHomeCount
        }
    }

    func workCount(_ locations: [QuadTreeLocation]) -> Int {
        if lastWorkCount == -1 {
        return allLocations().filter {
            return $0.time.isWorkCompliant()
        }.count
        } else {
            if lastLocation?.time.isWorkCompliant() ?? false {
                lastWorkCount = lastWorkCount + 1
            }
            return lastWorkCount
        }
    }

    func poisInProximity() -> [Poi] {
        var allpois = [Poi]()
        allpois.append(contentsOf:getPois())
        for neighbour in self.neighbours() {
            for n in neighbour.neighbours() {
                allpois.append(contentsOf:n.getPois())
            }
           // allpois.append(contentsOf:neighbour.getPois())
        }
        return allpois
    }
    

    func shoppingCount(_ locations: [QuadTreeLocation]) -> Int {
        var filteredLocations = [QuadTreeLocation]()
        for loc in allLocations() {
            var poisForlocation = [Poi]()
            for poi in poisInProximity() {
                let distance = CLLocation(latitude: poi.getLat(), longitude: poi.getLng()).distance(from: CLLocation(latitude: loc.lat, longitude: loc.lng))
                if distance < StorageConstants.shoppingMinRadius {
                    poisForlocation.append(poi)
                }
            }
            loc.setIsNearToPoi(poisForlocation.count > 0)
            if poisForlocation.count > 0 {
                filteredLocations.append(loc)
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

    func populateParentality() {
        for child in childs() {
            child.setParentNode(self)
            child.populateParentality()
        }
    }

    @discardableResult
    func  browseTree(_ location: QuadTreeLocation) -> QuadTreeNode? {
        var result: QuadTreeNode? = nil
        if rect.contains(location) {
            result = self
            for child in childs() {
                if child.getRect().contains(location ){
                    result =  child.browseTree(location)
                }
            }
        }
        return result
    }

    func getPois() -> [Poi] {
        return self.pois ?? [Poi]()
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
            child.setUpdated(true)
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

            if child == nil {
                child = createChildforLocation(location)
            } else {
              _ = child?.addLocation(location)
            }
        }
        locations.removeAll()
    }

    @discardableResult
    func addLocation(_ location: QuadTreeLocation) -> QuadTreeNode? {
        let count = self.allLocations().count
        populateLocation(location)
        if ((count <= getLimit() && !hasChildForLocation(location)) || rect.isMin()) {
            if !locationIsPresent(location) {
                GlobalLogger.shared.debug("addLocation node: \(treeId!) count: \(count) isMin? : \( rect.isMin()) limit: \(getLimit())")
                populateLocation(location)
                locations.append(location)
                lastLocation = location
                self.updated = true
                computeTags()
            }
            return self
        } else {
          return  splitNode(location)
        }
    }

    func populateLocation(_ loc : QuadTreeLocation) {
        var poisForlocation = [Poi]()
        for poi in poisInProximity() {
            let distance = CLLocation(latitude: poi.getLat(), longitude: poi.getLng()).distance(from: CLLocation(latitude: loc.lat, longitude: loc.lng))
            if distance < StorageConstants.shoppingMinRadius {
                poisForlocation.append(poi)
            }
        }
        loc.setIsNearToPoi(poisForlocation.count > 0)
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
        child.setParentNode(self)
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
        child.updated = true
        child.newBorn = true
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

    func addInList(_ list: [QuadTreeNode]?) ->  [QuadTreeNode] {
        var result = [QuadTreeNode]()
        guard let treeID = self.treeId, let list = list else {
            return result
        }
         result = Array(list)
        let idsList = list.map {$0.getTreeId()}
        if  !idsList.contains(treeID) {
            result.append(self)
        }
        return result
    }

    func isEqual(_ node: QuadTreeNode) -> Bool {
        return self.treeId == node.getTreeId()
    }

    func isNearToPoi() -> Bool {
        return self.locations.filter{$0.isNearToPoi()}.count  > 10 &&
            (self.densities?.count ?? 0)  > 0 &&
            self.getRect().circle().radius <=   StorageConstants.shoppingMinRadius &&
            self.densities?[LivingTag.shopping.rawValue] ?? 0 > 0
    }

   

    func neighbours() -> [QuadTreeNode] {
        var candidates = [QuadTreeNode]()
        candidates = walkUp()?.addInList(candidates) ?? candidates
        candidates = walkDown()?.addInList(candidates) ?? candidates
        candidates = walkRight()?.addInList(candidates) ?? candidates
        candidates = walkLeft()?.addInList(candidates) ?? candidates
        candidates = walkDownLeft()?.addInList(candidates) ?? candidates
        candidates = walkUpRight()?.addInList(candidates) ?? candidates
        candidates = walkUpLeft()?.addInList(candidates) ?? candidates
        candidates = walkDownRight()?.addInList(candidates) ?? candidates
        candidates = candidates.compactMap{$0}
        return candidates
    }

    func walkLeft() -> QuadTreeNode? {
        switch type() {
        case .rightUp:
            return getParentNode()?.getLeftUpChild()
        case .rightBottom:
            return getParentNode()?.getLeftBottomChild()
        case .leftUp:
            let leftParent = getParentNode()?.walkLeft()
            return leftParent?.getRightUpChild() ?? leftParent
        case .leftBottom:
            let leftParent = getParentNode()?.walkLeft()
            return leftParent?.getRightBottomChild() ?? leftParent
        default:
            return nil
        }
    }

    func walkRight() -> QuadTreeNode? {
        switch type() {
        case .rightUp:
            let rightParent = getParentNode()?.walkRight()
            return rightParent?.getLeftUpChild() ??  rightParent
        case .rightBottom:
            let rightParent = getParentNode()?.walkRight()
            return rightParent?.getLeftBottomChild() ?? rightParent
        case .leftUp:
            return  getParentNode()?.getRightUpChild()
        case .leftBottom:
            return  getParentNode()?.getRightBottomChild()
        default:
            return nil
        }
    }

    func walkUp() -> QuadTreeNode? {
        switch type() {
        case .rightUp:
            let upParent = getParentNode()?.walkUp()
            return upParent?.getRightBottomChild() ??  upParent
        case .rightBottom:
           return getParentNode()?.getRightUpChild()
        case .leftUp:
            let upParent = getParentNode()?.walkUp()
            return upParent?.getLeftBottomChild() ??  upParent
        case .leftBottom:
            return  getParentNode()?.getLeftUpChild()
        default:
            return nil
        }
    }

    func walkDown() -> QuadTreeNode? {
        switch type() {
        case .rightUp:
            return getParentNode()?.getRightBottomChild()
        case .rightBottom:
            let bottomParent = getParentNode()?.walkDown()
            return bottomParent?.getRightUpChild() ?? bottomParent
        case .leftUp:
            return getParentNode()?.getLeftBottomChild()
        case .leftBottom:
            let bottomParent = getParentNode()?.walkDown()
            return bottomParent?.getLeftUpChild() ?? bottomParent
        default:
            return nil
        }
    }

    func walkUpLeft() -> QuadTreeNode? {
        switch type() {
        case .leftUp:
            let upLeftParent = getParentNode()?.walkUpLeft()
            return upLeftParent?.getRightBottomChild() ?? upLeftParent
        case .rightBottom:
            return getParentNode()?.getLeftUpChild()
        case .rightUp:
            let upParent = getParentNode()?.walkUp()
            return upParent?.getLeftBottomChild() ?? upParent
        case .leftBottom:
            let bottomParent = getParentNode()?.walkLeft()
            return bottomParent?.getRightUpChild() ?? bottomParent
        default:
            return nil
        }
    }

    func walkDownLeft() -> QuadTreeNode? {
        switch type() {
        case .leftUp:
            let leftParent = getParentNode()?.walkLeft()
            return leftParent?.getRightBottomChild() ?? leftParent
        case .rightBottom:
            let bottomParent = getParentNode()?.walkDown()
            return bottomParent?.getLeftUpChild() ?? bottomParent
        case .rightUp:
            return getParentNode()?.getLeftBottomChild()
        case .leftBottom:
            let leftBottomParent = getParentNode()?.walkDownLeft()
            return leftBottomParent?.getRightUpChild() ?? leftBottomParent
        default:
            return nil
        }
    }

    func walkUpRight() -> QuadTreeNode? {
        switch type() {
        case .leftUp:
            let upParent = getParentNode()?.walkUp()
            return upParent?.getRightBottomChild() ?? upParent
        case .rightBottom:
            let rightParent = getParentNode()?.walkRight()
            return rightParent?.getLeftUpChild() ?? rightParent
        case .rightUp:
            let rightUpParent = getParentNode()?.walkUpRight()
            return rightUpParent?.getLeftBottomChild() ?? rightUpParent
        case .leftBottom:
            return getParentNode()?.getRightUpChild()
        default:
            return nil
        }
    }

    func walkDownRight() -> QuadTreeNode? {
        switch type() {
        case .leftUp:
            return getParentNode()?.getRightBottomChild()
        case .rightBottom:
            let rightBottomParent = getParentNode()?.walkDownRight()
            return rightBottomParent?.getLeftUpChild() ?? rightBottomParent
        case .rightUp:
            let rightParent = getParentNode()?.walkRight()
            return rightParent?.getLeftBottomChild() ?? rightParent
        case .leftBottom:
            let bottomParent = getParentNode()?.walkDown()
            return bottomParent?.getRightBottomChild() ?? bottomParent
        default:
            return nil
        }
    }

    func type()-> LeafType {
        let last: String = String(self.treeId?.last ?? "0")
        switch  LeafDirection(rawValue: last) {
        case .NW:
            return .leftUp
        case .NE:
            return .rightUp
        case .SW:
            return .leftBottom
        case .SE:
            return .rightBottom
        default:
            return .root
        }
    }
}

public class HerowQuadTreeLocation: QuadTreeLocation {

    public var lat: Double
    public var lng: Double
    public var time: Date
    public var nearToPoi = false

    public func isNearToPoi() -> Bool {
        return nearToPoi
    }

    public func setIsNearToPoi(_ near: Bool)  {
        nearToPoi = near
    }

    required public init(lat: Double, lng: Double, time: Date) {
        self.lat = lat
        self.lng = lng
        self.time = time
    }
}

public class HerowPeriod: PeriodProtocol {



    public var workLocations: [QuadTreeLocation] = [QuadTreeLocation]()
    public  var homeLocations: [QuadTreeLocation] = [QuadTreeLocation]()
    public var schoolLocations: [QuadTreeLocation] = [QuadTreeLocation]()
    public  var otherLocations: [QuadTreeLocation] = [QuadTreeLocation]()
    public  var poiLocations: [QuadTreeLocation] = [QuadTreeLocation]()
    public var start: Date
    public var end: Date
    public required init(workLocations: [QuadTreeLocation], homeLocations: [QuadTreeLocation], schoolLocations: [QuadTreeLocation], otherLocations: [QuadTreeLocation], poiLocations: [QuadTreeLocation], start: Date, end: Date) {
        self.start = start
        self.end = end
        self.homeLocations = homeLocations
        self.workLocations = workLocations
        self.schoolLocations = schoolLocations
        self.otherLocations = otherLocations
        self.poiLocations = poiLocations
    }



    public func getAllLocations() ->  [QuadTreeLocation] {
        return Array([ self.homeLocations,  self.workLocations,self.schoolLocations,self.otherLocations, self.poiLocations].joined()).sorted {$0.time > $1.time }
    }
}




