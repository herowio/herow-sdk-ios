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
    @NSManaged var bottomLeft: NodeCoreData?
    @NSManaged var bottomRight: NodeCoreData?
    @NSManaged var upRight: NodeCoreData?
    @NSManaged var upLeft: NodeCoreData?
    @NSManaged var parent: NodeCoreData?
    @NSManaged var geoHash: String
    @NSManaged var locations: [LocationCoreData]?
    @NSManaged var size: Int64
}
@objc(LocationCoreData)
class LocationCoreData: NSManagedObject {
    @NSManaged var time: Date
    @NSManaged var lat: Double
    @NSManaged var lng: Double
}

