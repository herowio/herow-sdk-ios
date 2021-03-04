//
//  GeoHashHelperTests.swift
//  herow_sdk_iosTests
//
//  Created by Damien on 04/03/2021.
//

import XCTest
import CoreLocation
@testable import herow_sdk_ios
class GeoHashHelperTests: XCTestCase {

    private let expectedEncodedGeoHash = "u4pruydqqvj8"
    private var locationToEncode: CLLocation!

    private let encodedGeoHashToDecode = "ezs42"
    private var locationToDecode: CLLocation!

    override func setUp() {
        locationToEncode = CLLocation(latitude: 57.64911, longitude: 10.40744)
        locationToDecode = CLLocation(latitude: 42.583, longitude: -5.625)
    }

    func testEncode() {
        let geoHash = GeoHashHelper.encodeBase32(lat: locationToEncode.coordinate.latitude, lng: locationToEncode.coordinate.longitude, bits: 5 * 12)
        XCTAssertEqual(expectedEncodedGeoHash, geoHash)
    }

    func testDecode() {
        let location = GeoHashHelper.decodeBase32(base32: encodedGeoHashToDecode)
        XCTAssertTrue(checkIsEqual(locationToDecode.coordinate.latitude, result: location.coordinate.latitude, includingNumberOfFractionalDigits: 3))
        XCTAssertTrue(checkIsEqual(locationToDecode.coordinate.longitude, result: location.coordinate.longitude, includingNumberOfFractionalDigits: 3))
    }

    private func checkIsEqual(_ expected: Double, result: Double, includingNumberOfFractionalDigits : Int) -> Bool {
        let denominator         : Double = pow(10.0, Double(includingNumberOfFractionalDigits))
        let maximumDifference   : Double = 1.0 / denominator
        let realDifference      : Double = fabs(expected - result)
        if realDifference >= maximumDifference {
            return false
        } else {
            return true
        }
    }

    /*
        UserLocation: 48.8801391,2.3545789
        CT: 48.8757615,2.347092
        Sacré coeur: 48.8875109,2.352408
        Evry: 48.6298625,2.424263 ~50 km
        Melun: 48.5421645,2.6377199 ~60 km
        Fontainebleau: 48.4236722,2.611691 ~80 km
        Orléans: 47.8735098,1.8421687, ~120 km
    */
    func testPlacesPresence() {
        var places = [String:String]()
        places["CT"] = GeoHashHelper.encodeBase32(lat: 48.8757615, lng: 2.347092)
        places["Sacré coeur"] = GeoHashHelper.encodeBase32(lat: 48.8875109, lng: 2.352408)
        places["Evry"] = GeoHashHelper.encodeBase32(lat: 48.6298625, lng: 2.424263)
        places["Melun"] = GeoHashHelper.encodeBase32(lat: 48.5421645, lng: 2.6377199)
        places["Fontainebleau"] = GeoHashHelper.encodeBase32(lat: 48.4236722, lng: 2.611691)
        places["Orléans"] = GeoHashHelper.encodeBase32(lat: 47.8735098, lng: 1.8421687)

        let distanceBetweenLocations: Double = 15000
        var locations = [CLLocation]()
        let userLocation = CLLocation.init(latitude: 48.8801391, longitude: 2.3545789)
        locations.append(userLocation)
        locations.append(LocationUtils.location(location: userLocation, byMovingDistance: distanceBetweenLocations, withBearing: 0))
        locations.append(LocationUtils.location(location: userLocation, byMovingDistance: distanceBetweenLocations, withBearing: 45))
        locations.append(LocationUtils.location(location: userLocation, byMovingDistance: distanceBetweenLocations, withBearing: 90))
        locations.append(LocationUtils.location(location: userLocation, byMovingDistance: distanceBetweenLocations, withBearing: 135))
        locations.append(LocationUtils.location(location: userLocation, byMovingDistance: distanceBetweenLocations, withBearing: 180))
        locations.append(LocationUtils.location(location: userLocation, byMovingDistance: distanceBetweenLocations, withBearing: -45))
        locations.append(LocationUtils.location(location: userLocation, byMovingDistance: distanceBetweenLocations, withBearing: -90))
        locations.append(LocationUtils.location(location: userLocation, byMovingDistance: distanceBetweenLocations, withBearing: -135))

        var loadedPlaces = [String]()
        for location in locations {
            let currentGeoHash = GeoHashHelper.encodeBase32(lat: location.coordinate.latitude, lng: location.coordinate.longitude)
            for (key, value) in places {
                if currentGeoHash.take(4) == value.take(4) {
                    if !loadedPlaces.contains(key) {
                        loadedPlaces.append(key)
                    }
                }
            }
        }
        XCTAssertTrue(loadedPlaces.contains("CT"))
        XCTAssertTrue(loadedPlaces.contains("Sacré coeur"))
    }

}
