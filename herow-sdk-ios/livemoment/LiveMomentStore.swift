//
//  LiveMomentStore.swift
//  herow_sdk_ios
//
//  Created by Damien on 11/05/2021.
//

import Foundation
import CoreLocation
protocol LiveMomentStoreProtocol: DetectionEngineListener {
    init(db: DataBase)
    func getNodeForLocation(_ location: CLLocation) -> QuadTreeNode?
    func getClusters() ->  QuadTreeNode?
    func getNodeForId(_ id: String) ->  QuadTreeNode?
    func getParentForNode(_ node: QuadTreeNode) -> QuadTreeNode?
}

class LiveMomentStore: LiveMomentStoreProtocol {
    private var isWorking = false
    func onLocationUpdate(_ location: CLLocation, from: UpdateType) {
        getNodeForLocation(location)
    }

    @discardableResult
    func getNodeForLocation(_ location: CLLocation)  -> QuadTreeNode? {
        if isWorking {
            return nil
        }
        isWorking = true
        let quadLocation = HerowQuadTreeLocation(lat: location.coordinate.latitude, lng: location.coordinate.longitude, time: location.timestamp)
        if let root = getClusters() {
            let result = root.browseTree(quadLocation)
             dataBase.saveQuadTree(root) {
                self.isWorking = false
            }
            return result
        }
        return nil
    }

    func getClusters() ->  QuadTreeNode? {
        return dataBase.getQuadTreeRoot()
    }

    func getNodeForId(_ id: String) ->  QuadTreeNode?  {
        return dataBase.getNodeForId(id)
    }

    func getParentForNode(_ node: QuadTreeNode) -> QuadTreeNode? {
        return getNodeForId(String(node.getTreeId().dropLast()))
    }

    let dataBase: DataBase
    required init(db: DataBase) {
        dataBase = db
    }

    func getRects() -> [NodeDescription]? {
        return dataBase.getQuadTreeRoot()?.getReccursiveRects(nil)
    }

}
