//
//  QuadTreeCoreData.swift
//  herow_sdk_ios
//
//  Created by Damien on 10/05/2021.
//

import Foundation
import CoreData
@objc(NodeCoreData)
class NodeCoreData: NSManagedObject {
    @NSManaged var childs:Set<NodeCoreData>?
    @NSManaged  var parent: NodeCoreData?
    @NSManaged var treeId: String
    @NSManaged var type: String
    @NSManaged var locations: Set<LocationCoreData>?
    @NSManaged var pois: Set<PoiCoreData>?
    @NSManaged var originLat: Double
    @NSManaged var originLng: Double
    @NSManaged var endLat: Double
    @NSManaged var endLng: Double
    @NSManaged var nodeTags:  [String: Double]
    @NSManaged var nodeDensities: [String: Double]

    func getChildForType(_ type: LeafType) ->  NodeCoreData?{
        return childs?.filter {
            $0.type == "\(type.rawValue)"
        }.first
    }

    func leftUp() -> NodeCoreData? {
        return getChildForType(.leftUp)
    }

    func leftBottom() -> NodeCoreData? {
        return getChildForType(.leftBottom)
    }

    func rightUp() -> NodeCoreData? {
        return getChildForType(.rightUp)
    }

    func rightBottom() -> NodeCoreData? {
        return getChildForType(.rightBottom)
    }

    func isRoot() -> Bool {
        return treeId == "\(LeafType.root.rawValue)"
    }

    func contains(_ loc: QuadTreeLocation) -> Bool {
        guard let locations = self.locations else {
            return false
        }
        let result =  !locations.filter {
            $0.lat == loc.lat && $0.lng == loc.lng && $0.time == loc.time
        }.isEmpty
        if result {
        print("location already in coredatanode")
        } else {
            print("new location in coredatanode")
        }
        return result
    }

    func contains(_ loc: LocationCoreData) -> Bool {
        guard let locations = self.locations else {
            return false
        }
        return !locations.filter {
            $0.lat == loc.lat && $0.lng == loc.lng && $0.time == loc.time
        }.isEmpty
    }

    func cleanLocations() {
        guard let locations = self.locations , let childs = self.childs, childs.count > 0 else {return}
        for loc in locations {
            for child in  childs {
                if child.contains(loc) {
                    self.locations?.remove(loc)
                }
            }
        }
    }
}
@objc(LocationCoreData)
class LocationCoreData: NSManagedObject {
    @NSManaged var time: Date
    @NSManaged var lat: Double
    @NSManaged var lng: Double
    @NSManaged var node: NodeCoreData
    @NSManaged var period: Period
    @NSManaged var isNearToPoi: Bool
//    @NSManaged var pois: Set<PoiCoreData>?


}

@objc(Period)
class Period: NSManagedObject {
    @NSManaged var start: Date
    @NSManaged var end: Date
    @NSManaged var locations: Set<LocationCoreData>?
}
