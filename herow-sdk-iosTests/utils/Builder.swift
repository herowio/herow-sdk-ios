//
//  Builder.swift
//  herow_sdk_ios
//
//  Created by Damien on 17/02/2021.
//

import Foundation
import CoreLocation
class Builder {

   private  static func createZones(locations: [CLLocationCoordinate2D], campaignNumber: Int) -> [APIZone] {
        return locations.map {
            let hash = "hash\($0.latitude)\($0.longitude)"
            var campaignIds = [String]()
            for i in 0...campaignNumber - 1 {
                campaignIds.append( "id-\(i)-\($0.latitude)\($0.longitude)")
            }

            let access = APIAccess(id: hash, name: hash, address: hash)

            return APIZone(hash: hash, lat: $0.latitude, lng: $0.longitude, radius: 100, campaigns: campaignIds, access: access, liveEvent: false)
        }
    }

    private  static func createPois(locations: [CLLocationCoordinate2D]) -> [APIPoi] {
         return locations.map {
             let id = "poiId\($0.latitude)\($0.longitude)"
             return APIPoi(id: id, tags: ["tag"], lat: $0.latitude, lng: $0.longitude)
         }
     }

    private static func createZonesAndCampaigns(locations: [CLLocationCoordinate2D], campaignNumber: Int) -> ([APIZone], [APICampaign]) {
        let zones = createZones(locations: locations, campaignNumber: campaignNumber)
        let campaignsIdsArrays: [[String]] = zones.map {
            return $0.campaigns
        }
        let campaignsIds: [String] = campaignsIdsArrays.reduce([]) { $0 + $1 }
        let campaigns =  campaignsIds.map {
            return APICampaign(id: $0, company: "company", name: $0, createdDate: 0, modifiedDate: 0, deleted: false, simpleId: $0, begin: 0, end: nil, realTimeContent: false, intervals: nil, cappings: nil, triggers: ["exit":0], daysRecurrence: [], recurrenceEnabled: false, tz: "tz", notification: nil)
        }

        return (zones, campaigns)

    }

     static func createLocations(number : Int, location: CLLocationCoordinate2D,  distance: Double = 100) -> [CLLocationCoordinate2D] {
        var result = [CLLocationCoordinate2D]()

        for i in 0...number - 1 {
            let newlocation = Builder.locationWithBearing(bearingRadians: 0, distanceMeters: distance * Double((i + 1)), origin: location)
            result.append(newlocation )
        }
        return result
    }

    static func locationWithBearing(bearingRadians:Double, distanceMeters:Double, origin:CLLocation) -> CLLocation {
        let coord = locationWithBearing(bearingRadians: bearingRadians, distanceMeters: distanceMeters, origin: origin.coordinate)
        return CLLocation(latitude: coord.latitude, longitude: coord.longitude)
    }


     private static func locationWithBearing(bearingRadians:Double, distanceMeters:Double, origin:CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        let distRadians = distanceMeters / (6372797.6) // earth radius in meters

        let lat1 = origin.latitude * .pi / 180
        let lon1 = origin.longitude * .pi / 180

        let lat2 = asin(sin(lat1) * cos(distRadians) + cos(lat1) * sin(distRadians) * cos(bearingRadians))
        let lon2 = lon1 + atan2(sin(bearingRadians) * sin(distRadians) * cos(lat1), cos(distRadians) - sin(lat1) * sin(lat2))

        return CLLocationCoordinate2D(latitude: lat2 * 180 / .pi, longitude: lon2 * 180 / .pi)
    }

    public static func create(zoneNumber: Int, campaignNumberPerZone: Int, from: CLLocationCoordinate2D, distance: Double = 100) -> ([APIZone], [APICampaign]){
        let locations = createLocations(number: zoneNumber, location: from, distance: distance)
        return createZonesAndCampaigns(locations: locations, campaignNumber: campaignNumberPerZone)
    }

    public static func createPois(number: Int, from: CLLocationCoordinate2D, distance: Double = 100) -> [APIPoi]{
        let locations = createLocations(number: number, location: from, distance: distance)
        return createPois(locations: locations)
    }

}
