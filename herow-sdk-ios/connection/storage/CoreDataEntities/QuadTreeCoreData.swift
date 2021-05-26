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
}
@objc(LocationCoreData)
class LocationCoreData: NSManagedObject {
    @NSManaged var time: Date
    @NSManaged var lat: Double
    @NSManaged var lng: Double
//    @NSManaged var pois: Set<PoiCoreData>?


}
