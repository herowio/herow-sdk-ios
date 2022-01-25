//
//  LogDataContext.swift
//  herow-sdk-ios
//
//  Created by Damien on 01/02/2021.
//

import Foundation
import CoreLocation

struct Moments: Codable {
    var home: Double
    var office: Double
    var shopping: Double
    var other: Double
}
class LogDataContext: LogData {

    var location :CLLocation
    var moments: Moments?
    var clickAndCollect: Bool
    init( appState: String, location: CLLocation, cacheManager: CacheManagerProtocol,dataStorage: HerowDataStorageProtocol? ,clickAndCollect: Bool, moments: Moments? = nil) {
        self.clickAndCollect = clickAndCollect
        self.location = location
        self.moments = moments
        super.init(appState: appState, cacheManager: cacheManager, dataStorage: dataStorage)
    }

    override func getData() -> Data? {
        let pois: [NearbyPoi] = cacheManager?.getNearbyPois(location).map {
            let distance = location.distance(from: CLLocation(latitude: $0.getLat(), longitude: $0.getLng()))
             return NearbyPoi(id: $0.getId(), distance: distance, tags: $0.getTags())
        } ?? [NearbyPoi]()

        let places: [NearbyPlace] = cacheManager?.getNearbyZones( self.location).map {
            let distance = location.distance(from: CLLocation(latitude: $0.getLat(), longitude: $0.getLng()))

            return NearbyPlace(placeId: $0.getHash(), distance: distance, radius: $0.getRadius(), lat: $0.getLat(), lng: $0.getLng(),confidence: nil )
        } ?? [NearbyPlace]()

        let logData = LogDataContextStruct(location: location, pois: pois, places: places, appState: self.appState, subtype: self.clickAndCollect ?  SubType.CONTEXT_REALTIME.rawValue : SubType.CONTEXT.rawValue, dataStorage: self.dataStorage, moments: self.moments)

        let log = Log(data: logData)
        return  log.encode()
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
    let confidence: Double?
    enum CodingKeys: String, CodingKey {
        case placeId = "place_id"
        case distance
        case radius
        case lat
        case lng
        case confidence
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(placeId, forKey: .placeId)
        try container.encode(distance, forKey: .distance)
        try container.encode(radius, forKey: .radius)
        try container.encode(lat, forKey: .lat)
        try container.encode(lng, forKey: .lng)
        try container.encodeIfPresent(confidence, forKey: .confidence)
    }
}

class LogDataContextStruct: LogDataStruct {
    let lastLocation: CLLocation?
    let nearbyPois: [NearbyPoi]
    let nearbyPlaces: [NearbyPlace]
    let moments: Moments?

    init( location: CLLocation, pois: [NearbyPoi], places: [NearbyPlace],appState: String, subtype: String, dataStorage: HerowDataStorageProtocol?, moments : Moments? = nil)  {
        self.lastLocation = location
        self.nearbyPois = pois
        self.nearbyPlaces = places
        self.moments = moments
        super.init(appState: appState, subtype: subtype, dataStorage: dataStorage)

    }

    enum CodingKeys: String, CodingKey {
        case lastLocation
        case nearbyPois
        case nearbyPlaces = "nearby_places"
        case moments
    }

    public override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(lastLocation, forKey: .lastLocation)
        try container.encodeIfPresent(moments, forKey: .moments)
        try container.encode(nearbyPois, forKey: .nearbyPois)
        try container.encode(nearbyPlaces, forKey: .nearbyPlaces)
    }
}
