//
//  PredictionStore.swift
//  FirebaseCore
//
//  Created by Damien on 17/12/2021.
//

import Foundation
import CoreLocation

protocol PredictionStoreListener: AnyObject {
    func didPredict(predictions: [Prediction])
    func didPredictionsForTags(predictions: [TagPrediction])
    func didZonePredict(predictions: [ZonePrediction])
}

protocol PredictionStoreProtocol: AnyObject, LiveMomentStoreListener {
    func registerListener(listener: PredictionStoreListener)
    func unregisterListener(listener: PredictionStoreListener)
}


public typealias LocationPattern = [String : Decimal]

extension LocationPattern {
    func sum() -> Decimal {
        var sum: Decimal = 0.0
        for (_ ,value) in self {
            sum = sum + value
        }
        return sum
    }

    func filtered() -> LocationPattern {
        return self.filter { $0.value > 0.1 }
    }


    public func snakeCaseValue() -> LocationPattern {
      return  Dictionary(uniqueKeysWithValues:
                            self.map { key, value in
          return (key.replacingOccurrences(of: " ", with: "_"), value.round(to:2)) })
    }
}


public protocol Predictable: Codable {
}

extension Predictable  {
    func printValue()  {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        guard  let data = try? encoder.encode(self) else {
            return
        }
        print(String(decoding: data, as: UTF8.self))
    }
}


public struct Prediction: Predictable {
    var pois: [HerowPoi]
    var coordinates: CodableCoordinates
    var pattern: LocationPattern
    enum CodingKeys: String, CodingKey {
        case pois
        case coordinates
        case pattern
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(pois, forKey: .pois)
        try container.encode(coordinates, forKey: .coordinates)
        try container.encode(pattern.snakeCaseValue() , forKey: .pattern)
    }
}

private struct TagObject {
    var tag: String
    var new = true
    var locations: [QuadTreeLocation]
    var recurencies =  [RecurencyDay: Int]()
    mutating func addLocation(_ loc: QuadTreeLocation) {
         self.locations.append(loc)
        computeRecurency(loc)
    }

    mutating func addLocations(_ locs: [QuadTreeLocation]) {
        for loc in locs {
            addLocation(loc)
        }
    }

    public mutating func computeRecurency(_ loc: QuadTreeLocation) {
        let day = loc.time.recurencyDay
        var value: Int = self.recurencies[day] ?? 0
        value = value + 1
        self.recurencies[day] = value
    }

    public  func getLocationPattern() -> LocationPattern {
        let count: Double  = Double( self.locations.count)
        var pattern = LocationPattern()
        for (key, value) in self.recurencies {
            pattern[key.rawValue()] = Decimal((Double(value) / count).round(to: 2))
        }
        return pattern.filtered()
    }

    func toTagPrediction() -> TagPrediction {
        return TagPrediction(tag: self.tag, pattern: getLocationPattern())
    }
}

public struct TagPrediction: Predictable {
    var tag: String
    var pattern: LocationPattern

    enum CodingKeys: String, CodingKey {
        case tag
        case pattern
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(tag, forKey: .tag)
        try container.encode(pattern.snakeCaseValue() , forKey: .pattern)
    }
}

public struct ZonePrediction: Predictable {
    var zoneHash: String
    var pattern: LocationPattern

    enum CodingKeys: String, CodingKey {
        case zoneHash = "id"
        case pattern
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(zoneHash, forKey: .zoneHash)
        try container.encode(pattern.snakeCaseValue() , forKey: .pattern)
    }
}


extension Array where Element == TagPrediction  {
    func printValue()  {
        guard let data = self.encode() else {
            return
        }
        print(String(decoding: data, as: UTF8.self))
    }

    func encode() -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        guard  let data = try? encoder.encode(self) else {
            return nil
        }
        return data
    }

    static func decode(_ data: Data) -> [TagPrediction]? {
        let decoded = try? JSONDecoder().decode([TagPrediction].self, from: data)
        return decoded
    }
}

 extension Array where Element == Prediction  {
     func printValue()  {
         guard let data = self.encode() else {
             return
         }
         print(String(decoding: data, as: UTF8.self))
     }

     func encode() -> Data? {
         let encoder = JSONEncoder()
         encoder.outputFormatting = .prettyPrinted
         guard  let data = try? encoder.encode(self) else {
             return nil
         }
         return data
     }

     static func decode(_ data: Data) -> [Prediction]? {
         let decoded = try? JSONDecoder().decode([Prediction].self, from: data)
         return decoded
     }
 }

extension Array where Element == ZonePrediction  {
    func printValue()  {
        guard let data = self.encode() else {
            return
        }
        print(String(decoding: data, as: UTF8.self))
    }

    func encode() -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        guard  let data = try? encoder.encode(self) else {
            return nil
        }
        return data
    }

    static func decode(_ data: Data) -> [ZonePrediction]? {
        let decoded = try? JSONDecoder().decode([ZonePrediction].self, from: data)
        return decoded
    }
}


class PredictionStore: PredictionStoreProtocol{

    var listeners =  [WeakContainer<PredictionStoreListener>]()
    var database : DataBase

    init( dataBase: DataBase) {
        self.database = dataBase
    }

    deinit {
        for listener in listeners.compactMap({$0.get()}) {
            self.unregisterListener(listener: listener)
        }
    }
    
    func registerListener(listener: PredictionStoreListener) {
        let first = listeners.first {
            ($0.get() === listener) == true
        }
        if first == nil {
            listeners.append(WeakContainer<PredictionStoreListener>(value: listener))
        }
    }

    func unregisterListener(listener: PredictionStoreListener) {
        listeners = listeners.filter {
            ($0.get() === listener) == false
        }
    }
    func liveMomentStoreStartComputing() {
        //do nothing
    }

    func didCompute(rects: [NodeDescription]?, home: QuadTreeNode?, work: QuadTreeNode?, school: QuadTreeNode?, shoppings: [QuadTreeNode]?, others: [QuadTreeNode]?, neighbours: [QuadTreeNode]?, periods: [PeriodProtocol]) {

        guard let shoppings = shoppings else {
            return
        }

        for listener in listeners {
                listener.get()?.didPredict(predictions: processShoppingZonesPredictions(shops: shoppings))
                listener.get()?.didPredictionsForTags(predictions: processTagsPredictions(shops: shoppings))
        }

        self.database.zonesStats { [unowned self] zonesPredictions in
            if !zonesPredictions.isEmpty {
                for listener in self.listeners {
                    listener.get()?.didZonePredict(predictions: zonesPredictions)
                }
            }
        }
    }

    func processShoppingZonesPredictions(shops: [QuadTreeNode]) -> [Prediction] {
        var predictions = [Prediction]()
        for shop in shops {
            let coordinates = shop.getRect().circle().center
            var allPois = [Poi]()
            allPois.append(contentsOf: shop.getPois())
            for n in shop.neighbours() {
                allPois.append(contentsOf: n.getPois())
            }
            if allPois.count > 0 {
            predictions.append(Prediction(pois: (allPois as? [HerowPoi]) ?? [], coordinates: CodableCoordinates(coordinates),pattern: shop.getLocationPattern()))
            }
        }
        return predictions
    }

    func processTagsPredictions(shops: [QuadTreeNode]) -> [TagPrediction] {
        var tagsObjects = [TagObject]()
        for shop in shops {
            for poi in shop.getPois() {
                for tag in poi.getTags() {
                    var currentTag = tagsObjects.filter {
                        $0.tag == tag
                    }.first ?? TagObject(tag: tag, locations: [QuadTreeLocation]())
                    currentTag.addLocations(shop.getLocations())
                    if currentTag.new {
                        currentTag.new = false
                        tagsObjects.append(currentTag)
                    }
                }
            }
        }
        return tagsObjects.map {
            $0.toTagPrediction()
        }.filter {
            !$0.pattern.isEmpty
        }
    }

    func didChangeNode(node: QuadTreeNode) {
        //do nothing
    }

    func getFirstLiveMoments(home: QuadTreeNode?, work: QuadTreeNode?, school: QuadTreeNode?, shoppings: [QuadTreeNode]?) {
        //do nothing
    }
}
