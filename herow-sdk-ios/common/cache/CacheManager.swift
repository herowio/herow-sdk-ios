//
//  CacheManager.swift
//  herow-sdk-ios
//
//  Created by Damien on 25/01/2021.
//

import Foundation
import CoreLocation


enum CacheUpdate {
    case zone
    case poi
    case campaign
    case delete
}

@objc public protocol CacheListener: class {
    func onCacheUpdate()
    func willCacheUpdate()
}

protocol CacheManagerProtocol {
    init(db: DataBase)

    func save(zones: [Zone]?,campaigns: [Campaign]?, pois: [Poi]?,  completion:(()->())?)
    func getZones() -> [Zone]
    func getZones(ids: [String])-> [Zone]
    func getPois() -> [Poi]
    func getCampaigns() -> [Campaign]
    func getCampaignsForZone(_ zone: Zone) -> [Campaign]
    func getNearbyZones(_ location: CLLocation) -> [Zone]
    func getNearbyPois(_ location: CLLocation) -> [Poi]
    func cleanCache(_ completion:(()->())?) 
    func registerCacheListener(listener: CacheListener)
    func unregisterCacheListener(listener: CacheListener)
    func didSave()
}

extension CacheManagerProtocol {
    func getNearbyPois(_ location: CLLocation, distance: CLLocationDistance, count: Int ) -> [Poi] {
        let pois = getPois().filter {
            let locationToCompare = CLLocation(latitude: $0.getLat(), longitude: $0.getLng())
            return location.distance(from: locationToCompare) <= distance
        }
        return Array(pois.sorted(by: {
            let locationToCompare1 = CLLocation(latitude: $0.getLat(), longitude: $0.getLng())
            let locationToCompare2 = CLLocation(latitude: $1.getLat(), longitude: $1.getLng())
            return location.distance(from: locationToCompare1) < location.distance(from: locationToCompare2)
        }).prefix(count))
    }

    func getNearbyZones(_ location: CLLocation, distance: CLLocationDistance) -> [Zone] {
        let zones = getZones().filter {
            let locationToCompare = CLLocation(latitude: $0.getLat(), longitude: $0.getLng())
            return location.distance(from: locationToCompare) <= distance
        }
        return zones.sorted(by: {
            let locationToCompare1 = CLLocation(latitude: $0.getLat(), longitude: $0.getLng())
            let locationToCompare2 = CLLocation(latitude: $1.getLat(), longitude: $1.getLng())
            return location.distance(from: locationToCompare1) < location.distance(from: locationToCompare2)
        })
    }
}

class CacheManager: CacheManagerProtocol {


    static let distanceThreshold: CLLocationDistance = 20_000
    static let maxNearByPoiCount: Int = 10
    let db: DataBase
    internal var listeners = [WeakContainer<CacheListener>]()

    required init(db: DataBase) {
        self.db = db
    }


    func save(zones: [Zone]?,campaigns: [Campaign]?, pois: [Poi]?,  completion:(()->())?) {
        willSave()
        if let zones = zones {
            saveZones(items: zones) {
                if let campaigns = campaigns {
                    self.saveCampaigns(items: campaigns) {
                        if let pois = pois {
                            self.savePois(items: pois) {
                                self.didSave()
                                completion?()
                            }
                        } else {
                            self.didSave()
                            completion?()
                        }
                    }
                } else {
                    self.didSave()
                    completion?()
                }
            }
        } else {
            self.didSave()
            completion?()
        }
    }

    func saveZones(items: [Zone], completion:(()->())?)  {
        self.db.saveZonesInBase(items: items, completion: completion)

    }

    func savePois(items: [Poi], completion:(()->())?)  {
        self.db.savePoisInBase(items: items, completion: completion)

    }

    func saveCampaigns(items: [Campaign], completion:(()->())?) {
        self.db.saveCampaignsInBase(items: items, completion: completion)
    }

    func willSave() {
        for listener in listeners {
            listener.get()?.willCacheUpdate()
        }
    }
    func didSave() {
        for listener in listeners {
            listener.get()?.onCacheUpdate()
        }
    }

    func getZones(ids: [String])-> [Zone] {
        return self.db.getZonesInBase().filter {
            ids.contains($0.getHash())
        }
    }
    
    func getZones() -> [Zone] {
        return  self.db.getZonesInBase()
    }

    func getPois() -> [Poi] {
        return  self.db.getPoisInBase()
    }

    func getCampaigns() -> [Campaign] {
        return  self.db.getCampaignsInBase()
    }

    func getCampaignsForZone(_ zone: Zone) -> [Campaign] {
        let campaignIds = zone.getCampaigns
        return getCampaigns().filter {
            campaignIds().contains( $0.getId())
        }
    }

    func getNearbyZones(_ location: CLLocation) -> [Zone] {
        getNearbyZones(location, distance: CacheManager.distanceThreshold)
    }

    func getNearbyPois(_ location: CLLocation) -> [Poi] {
        getNearbyPois(location, distance: CacheManager.distanceThreshold, count: CacheManager.maxNearByPoiCount)
    }

    func cleanCache(_ completion:(()->())? = nil) {
        db.purgeAllData() { [self] in
            completion?()
            for listener in listeners {
                listener.get()?.onCacheUpdate()
            }
        }
    }

    func registerCacheListener(listener: CacheListener) {
        let first = listeners.first {
            ($0.get() === listener) == true
        }
        if first == nil {
            listeners.append(WeakContainer<CacheListener>(value: listener))
        }
    }

    func unregisterCacheListener(listener: CacheListener) {
        listeners = listeners.filter {
            ($0.get() === listener) == false
        }
    }
}
