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
    @NSManaged var liveMomentTypes: [Int]
    @NSManaged var recurencies: [String: Int64]

    func addLiveMomentType(_ type: NodeType) {
        if !liveMomentTypes.contains(type.rawValue) {
            liveMomentTypes.append(type.rawValue)
        }
    }

    func removeLiveMomentType(_ type: NodeType) {
        if liveMomentTypes.contains(type.rawValue) {
            liveMomentTypes.removeAll { $0 == type.rawValue
            }
        }
    }

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
            GlobalLogger.shared.debug("location already in coredatanode")
        } else {
            GlobalLogger.shared.debug("new location in coredatanode")
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

    func computeRecurency() {
        self.recurencies =  [String: Int64]()
        locations?.forEach({ loc in
          let day =   loc.time.recurencyDay
          //  let slot = loc.time.slot
            var value = self.recurencies[day.rawValue()] ?? 0
            print("conmputed recurencie \( day)")
            value = value + 1
            self.recurencies[day.rawValue()] = value
        })
    }

    func getRecurencies() -> [RecurencyDay: Int] {
        var recurencies = [RecurencyDay: Int]()
        for key in self.recurencies.keys {
            
            let day = key.toRecurencyDay()
            let value = self.recurencies[key] ?? 0
            recurencies[day] = Int(value)
        }
        return recurencies
    }

}
@objc(LocationCoreData)
class LocationCoreData: NSManagedObject {
    @NSManaged var time: Date
    @NSManaged var lat: Double
    @NSManaged var lng: Double
    @NSManaged var node: NodeCoreData
    @NSManaged var period: Period
    @NSManaged var containers:  Set<LocationContainer>
    @NSManaged var isNearToPoi: Bool
//    @NSManaged var pois: Set<PoiCoreData>?

    func getType() -> String {
        if time.isHomeCompliant() {
            return "home"
        }
       else if time.isSchoolCompliant() {
            return "school"
        }
       else if time.isWorkCompliant() {
            return "work"
        }
        return "other"
    }

}

@objc (LocationContainer)
class LocationContainer: NSManagedObject {
    @NSManaged var  type: String
    @NSManaged var  locations: Set<LocationCoreData>?
    @NSManaged var period: Period?
}
@objc(Period)
class Period: NSManagedObject {
    @NSManaged var start: Date
    @NSManaged var end: Date
    @NSManaged var locations: Set<LocationCoreData>?
    @NSManaged var containers: Set<LocationContainer>?
}
