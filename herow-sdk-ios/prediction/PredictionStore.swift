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
        try container.encode(pattern, forKey: .pattern)
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


class PredictionStore: PredictionStoreProtocol{

    var listeners =  [WeakContainer<PredictionStoreListener>]()
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

    }

    func didChangeNode(node: QuadTreeNode) {
        //do nothing
    }

    func getFirstLiveMoments(home: QuadTreeNode?, work: QuadTreeNode?, school: QuadTreeNode?, shoppings: [QuadTreeNode]?) {
        //do nothing
    }

}
