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
    func didZonePredict(predictions: [ZonePrediction])
}

protocol PredictionStoreProtocol: AnyObject, LiveMomentStoreListener {
    func registerListener(listener: PredictionStoreListener)
    func unregisterListener(listener: PredictionStoreListener)
}


public typealias LocationPattern = [String : Double]

extension LocationPattern {
    func sum() -> Double {
        var sum = 0.0
        for (_ ,value) in self {
            sum = sum + value
        }
        return sum
    }

    func snakeCaseValue() -> LocationPattern {
      return  Dictionary(uniqueKeysWithValues:
                            self.map { key, value in (key.replacingOccurrences(of: " ", with: "_"), value) })
    }
}

public struct Prediction: Codable {
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

    func printValue()  {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        guard  let data = try? encoder.encode(self) else {
            return
        }
       // print("Predictions for shopping sum : \(self.pattern.sum())")
        print(String(decoding: data, as: UTF8.self))
    }
}


public struct ZonePrediction: Codable {
    var zoneHash: String
    var pattern: LocationPattern

    enum CodingKeys: String, CodingKey {
        case zoneHash
        case pattern

    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(zoneHash, forKey: .zoneHash)
        try container.encode(pattern.snakeCaseValue() , forKey: .pattern)
    }

    
    

    func printValue()  {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        guard  let data = try? encoder.encode(self) else {
            return
        }
       // print("Predictions for shopping sum : \(self.pattern.sum())")
        print(String(decoding: data, as: UTF8.self))
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

        var predictions = [Prediction]()
        for shop in shoppings {
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
        if !predictions.isEmpty {
            for listener in listeners {
                listener.get()?.didPredict(predictions: predictions)
            }
        }

        self.database.zonesStats { zonesPredictions in
            if !zonesPredictions.isEmpty {
                for listener in self.listeners {
                    listener.get()?.didZonePredict(predictions: zonesPredictions)
                }
            }
        }
    }

    func didChangeNode(node: QuadTreeNode) {
        //do nothing
    }

    func getFirstLiveMoments(home: QuadTreeNode?, work: QuadTreeNode?, school: QuadTreeNode?, shoppings: [QuadTreeNode]?) {
        //do nothing
    }

}
