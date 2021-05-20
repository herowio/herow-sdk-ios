//
//  LiveMomentStore.swift
//  herow_sdk_ios
//
//  Created by Damien on 11/05/2021.
//

import Foundation
import CoreLocation

 
protocol LiveMomentStoreProtocol: DetectionEngineListener, AppStateDelegate {
    init(db: DataBase, storage: HerowDataStorageProtocol)
    func getNodeForLocation(_ location: CLLocation) -> QuadTreeNode?
    func getClusters() ->  QuadTreeNode?
    func getNodeForId(_ id: String) ->  QuadTreeNode?
    func getParentForNode(_ node: QuadTreeNode) -> QuadTreeNode?
    func getHome() -> QuadTreeNode?
    func getWork() -> QuadTreeNode?
    func getSchool() -> QuadTreeNode?
    func getShopping() -> [QuadTreeNode]?
}

class LiveMomentStore: LiveMomentStoreProtocol {
    required init(db: DataBase, storage: HerowDataStorageProtocol) {
        self.dataBase = db
        self.dataStorage = storage
        self.root = self.getClusters()
    }

    func onAppInForeground() {
        save()
    }

    func onAppInBackground() {
        save()
    }

    func onAppTerminated() {
        save()
    }

    func save(_ force: Bool = true) {
        let lastSaveDate = self.dataStorage?.getLiveMomentLastSaveDate() ?? Date(timeIntervalSince1970: 0)
        let now = Date()
        let shouldSave = lastSaveDate.addingTimeInterval(600) < now || force
        if shouldSave {
            if let root = self.root {
                if isSaving  || isWorking{
                    return
                }
                isSaving = true
                dataBase.saveQuadTree(root) {
                    self.isSaving = false
                    self.dataStorage?.saveLiveMomentLastSaveDate(now)
                }
            }
        }
    }

    private var isWorking = false
    private var isSaving = false
    private var root: QuadTreeNode?
    private var dataStorage: HerowDataStorageProtocol?
    func onLocationUpdate(_ location: CLLocation, from: UpdateType) {
        getNodeForLocation(location)
    }

    @discardableResult
    func getNodeForLocation(_ location: CLLocation)  -> QuadTreeNode? {
        var result : QuadTreeNode?
        if isWorking {
            return result
        }
        isWorking = true
        let quadLocation = HerowQuadTreeLocation(lat: location.coordinate.latitude, lng: location.coordinate.longitude, time: location.timestamp)

        if let rootToUse = self.root {
            let node = rootToUse.browseTree(quadLocation)
            isWorking = false
            save(false)
            result = node
        }
      return result
    }

    func getClusters() ->  QuadTreeNode? {
        return dataBase.getQuadTreeRoot()
    }

    func getNodeForId(_ id: String) ->  QuadTreeNode?  {
        var result :  QuadTreeNode?
        if let root = self.root  {
            result = root.findNodeWithId(id)
        }
        return result
    }

    func getParentForNode(_ node: QuadTreeNode) -> QuadTreeNode? {
        return node.getParentNode()
    }

    let dataBase: DataBase
    required init(db: DataBase) {
        dataBase = db
    }

    func getRects() -> [NodeDescription]? {
        return self.root?.getReccursiveRects(nil)
    }

    func getHome() -> QuadTreeNode? {
        let nodes = getRects()?.filter {
            $0.locations.count > 10 &&
            ($0.densities?.count ?? 0)  > 0 &&
            $0.densities?[LivingTag.home.rawValue] ?? 0 > 0
            
        }.sorted {
           return $0.densities?[LivingTag.home.rawValue] ?? 0 < $1.densities?[LivingTag.home.rawValue] ?? 0
        }
        if let id = nodes?.first?.treeId {
            return getNodeForId(id)
        }
        return nil
    }

    func getWork() -> QuadTreeNode? {
        let nodes = getRects()?.filter {
            $0.locations.count > 10 &&
            ($0.densities?.count ?? 0)  > 0 &&
            $0.densities?[LivingTag.work.rawValue] ?? 0 > 0

        }.sorted {
          return  $0.densities?[LivingTag.work.rawValue] ?? 0 < $1.densities?[LivingTag.work.rawValue] ?? 0
        }
        if let id = nodes?.first?.treeId {
            return getNodeForId(id)
        }
        return nil
    }

    func getSchool() -> QuadTreeNode? {
        let nodes = getRects()?.filter {
            $0.locations.count > 10 &&
            ($0.densities?.count ?? 0)  > 0 &&
            $0.densities?[LivingTag.school.rawValue] ?? 0 > 0

        }.sorted {
          return  $0.densities?[LivingTag.school.rawValue] ?? 0 < $1.densities?[LivingTag.school.rawValue] ?? 0
        }
        if let id = nodes?.first?.treeId {
            return getNodeForId(id)
        }
        return nil
    }

    func getShopping() -> [QuadTreeNode]? {
        let nodes = getRects()?.filter {

            ($0.densities?.count ?? 0)  > 0 &&
            $0.densities?[LivingTag.shopping.rawValue] ?? 0 > 0

        }
        guard let newnodes = nodes else {
            return nil
        }
        var result = [QuadTreeNode]()
        for node in newnodes {
            if let wrappedNode = getNodeForId(node.treeId) {
                if wrappedNode.getRect().circle().radius <  StorageConstants.shoppingMinRadius {
                result.append(wrappedNode)
                }
            }
        }
        return result

    }

}
