//
//  LogDataContext.swift
//  herow-sdk-ios
//
//  Created by Damien on 01/02/2021.
//

import Foundation
import CoreLocation

class LogDataContext: LogData {

    var location :CLLocation
    var clickAndCollect: Bool
    init( appState: String, location: CLLocation, cacheManager: CacheManagerProtocol,dataStorage: HerowDataStorageProtocol? ,clickAndCollect: Bool) {
        self.clickAndCollect = clickAndCollect
        self.location = location
        super.init(appState: appState, cacheManager: cacheManager, dataStorage: dataStorage)
    }

    override func getData() -> Data? {
        let pois: [NearbyPoi] = cacheManager?.getNearbyPois(location).map {
            let distance = location.distance(from: CLLocation(latitude: $0.getLat(), longitude: $0.getLng()))
             return NearbyPoi(id: $0.getId(), distance: distance, tags: $0.getTags())
        } ?? [NearbyPoi]()

        let places: [NearbyPlace] = cacheManager?.getNearbyZones( self.location).map {
            let distance = location.distance(from: CLLocation(latitude: $0.getLat(), longitude: $0.getLng()))

           return NearbyPlace(placeId: $0.getHash(), distance: distance, radius: $0.getRadius(), lat: $0.getLat(), lng: $0.getLng())
        } ?? [NearbyPlace]()



        let logData = LogDataContextStruct(location: location, pois: pois, places: places, appState: self.appState, subtype: self.clickAndCollect ? "CONTEXT_REALTIME" : "CONTEXT", dataStorage: self.dataStorage)

        return  logData.encode()
    }
}


struct NearbyPoi: Encodable {
    let id : String
    let distance: Double
    let tags: [String]
}


struct NearbyPlace: Encodable {
    let placeId : String
    let distance: Double
    let radius: Double
    let lat: Double
    let lng: Double
    enum CodingKeys: String, CodingKey {
        case placeId = "place_id"
        case distance
        case radius
        case lat
        case lng
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(placeId, forKey: .placeId)
        try container.encode(distance, forKey: .distance)
        try container.encode(radius, forKey: .radius)
        try container.encode(lat, forKey: .lat)
        try container.encode(lng, forKey: .lng)
    }
}

class LogDataContextStruct: LogDataStruct {
    let lastLocation: CLLocation?
    let nearbyPois: [NearbyPoi]
    let nearbyPlaces: [NearbyPlace]

    init( location: CLLocation, pois: [NearbyPoi], places: [NearbyPlace],appState: String, subtype: String, dataStorage: HerowDataStorageProtocol?)  {
        self.lastLocation = location
        self.nearbyPois = pois
        self.nearbyPlaces = places
        super.init(appState: appState, subtype: subtype, dataStorage: dataStorage)

    }

    enum CodingKeys: String, CodingKey {
        case lastLocation
        case nearbyPois
        case nearbyPlaces = "nearby_places"

    }

    public override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(lastLocation, forKey: .lastLocation)
        try container.encode(nearbyPois, forKey: .nearbyPois)
        try container.encode(nearbyPlaces, forKey: .nearbyPlaces)
    }
}
