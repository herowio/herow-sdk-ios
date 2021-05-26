//
//  LiveMomentStore.swift
//  herow_sdk_ios
//
//  Created by Damien on 11/05/2021.
//

import Foundation
import CoreLocation


public protocol LiveMomentStoreListener {
    func  didCompute( rects: [NodeDescription]?, home: QuadTreeNode?, work: QuadTreeNode?, school: QuadTreeNode?, shoppings: [QuadTreeNode]?, others: [QuadTreeNode]?)
}

protocol LiveMomentStoreProtocol: DetectionEngineListener, AppStateDelegate, CacheListener {
    init(db: DataBase, storage: HerowDataStorageProtocol)
    func getNodeForLocation(_ location: CLLocation) -> QuadTreeNode?
    func getClusters() ->  QuadTreeNode?
    func getNodeForId(_ id: String) ->  QuadTreeNode?
    func getParentForNode(_ node: QuadTreeNode) -> QuadTreeNode?
    func getHome() -> QuadTreeNode?
    func getWork() -> QuadTreeNode?
    func getSchool() -> QuadTreeNode?
    func getShopping() -> [QuadTreeNode]?
    func registerLiveMomentStoreListener(_ listener: LiveMomentStoreListener )
}

class LiveMomentStore: LiveMomentStoreProtocol {

    private var isWorking = false
    private var isOnBackground = false
    private var isSaving = false
    private var root: QuadTreeNode?
    private var currentNode: QuadTreeNode?
    private var count = 0
    private var dataStorage: HerowDataStorageProtocol?
    private var home: QuadTreeNode?
    private var work: QuadTreeNode?
    private var school: QuadTreeNode?
    private var shoppings: [QuadTreeNode]?
    private var others: [QuadTreeNode]?
    private var rects: [NodeDescription]?
    private let dataBase: DataBase
    private var listeners = [WeakContainer<LiveMomentStoreListener>]()

    required init(db: DataBase, storage: HerowDataStorageProtocol) {
        self.dataBase = db
        self.dataStorage = storage
        self.setup()
    }

    func setup() {
        DispatchQueue.global(qos: .background).async {
            let start = CFAbsoluteTimeGetCurrent()
            print("LiveMomentStore start setup ")
            self.dataBase.createQuadTreeRoot {
                let endRoot = CFAbsoluteTimeGetCurrent()
                var  elapsedTime = (endRoot - start) * 1000
                print("LiveMomentStore createQuadTreeRoot took \(elapsedTime) ms ")
                self.root = self.getClustersInBase()
                self.compute()
                let end = CFAbsoluteTimeGetCurrent()
                 elapsedTime = (end - start) * 1000
                print("LiveMomentStore setup took \(elapsedTime) ms ")
            }
        }
    }
    func registerLiveMomentStoreListener(_ listener: LiveMomentStoreListener) {
        listeners.append(WeakContainer(value: listener))
    }

    func onAppInForeground() {
        isOnBackground = false
    }

    func onAppInBackground() {
        isOnBackground = true
    }

    func onAppTerminated() {
        save()
    }

    func onCacheUpdate(forGeoHash: String?) {

        guard let geoHash = forGeoHash,  let lastGeoHash = dataStorage?.getLastGeoHash() else {
            return
        }
        if geoHash == lastGeoHash {
            return
        }
        let start = CFAbsoluteTimeGetCurrent()
        print("LiveMomentStore reloadNewPois ")
        DispatchQueue.global(qos: .background).async {
            self.dataBase.reloadNewPois {
                self.root = self.getClustersInBase()
                self.compute()
                let end = CFAbsoluteTimeGetCurrent()
                let elapsedTime = (end - start) * 1000
                print("LiveMomentStore reloadNewPois took \(elapsedTime) ms ")
            }
        }
    }

    func willCacheUpdate() {

    }

    func onLocationUpdate(_ location: CLLocation, from: UpdateType) {

        if self.root == nil  {
            return
        }

        let process = {

            self.currentNode = self.getNodeForLocation(location)
            self.count = self.count + 1
        }
        print("LiveMomentStore on location update")
        if isOnBackground {
            process()
        } else {
            DispatchQueue.global(qos: .default).async {
                process()
            }
        }
    }

     func getRects() -> [NodeDescription]? {
        return self.rects
    }

    func getClusters() -> QuadTreeNode? {
        return self.root
    }

    func getHome() -> QuadTreeNode? {
        return home
    }

    func getWork() -> QuadTreeNode? {
        return work
    }

    func getSchool() -> QuadTreeNode? {
        return school
    }

    func getShopping() -> [QuadTreeNode]? {
        return shoppings
    }

    func getParentForNode(_ node: QuadTreeNode) -> QuadTreeNode? {
        return node.getParentNode()
    }


    internal func save(_ force: Bool = false, _ node: QuadTreeNode? = nil ) {
        let lastSaveDate = self.dataStorage?.getLiveMomentLastSaveDate() ?? Date(timeIntervalSince1970: 0)
        let now = Date()
        let shouldSave = lastSaveDate.addingTimeInterval(600) < now || force || count > 5
       print("LiveMomentStore  should save \(shouldSave)")
        if true {
            if let root = self.root {
                if isSaving  || isWorking{
                   print("LiveMomentStore  will not save because isSaving : \(isSaving) isWorking: \(isWorking)")

                    return
                }
                isSaving = true
                let nodeToSave = node?.getParentNode() ?? root
                print("LiveMomentStore  will save node: \(nodeToSave.getTreeId())")
                dataBase.saveQuadTree(nodeToSave) {
                    self.isSaving = false
                    self.dataStorage?.saveLiveMomentLastSaveDate(now)
                    print("LiveMomentStore  did save node: \(nodeToSave.getTreeId())")
                    self.count = 0
                }
            }
        } else {

        }
    }

    @discardableResult
    internal  func getNodeForLocation(_ location: CLLocation)  -> QuadTreeNode? {
        var result : QuadTreeNode?
        if isWorking == true {
            print("LiveMomentStore will not browse tree")
            isWorking = false
            return result
        }
        isWorking = true
        let quadLocation = HerowQuadTreeLocation(lat: location.coordinate.latitude, lng: location.coordinate.longitude, time: location.timestamp)
        var nodeToUse = self.currentNode ?? self.root
        if currentNode?.getRect().contains(quadLocation) ?? false {
            print("LiveMomentStore should get parent node")
        }
        while (!(nodeToUse?.getRect().contains(quadLocation) ?? false)) {
            nodeToUse = nodeToUse?.getParentNode()
        }
        if let rootToUse = nodeToUse {
            print("LiveMomentStore will  browse node: \(rootToUse.getTreeId())")
            let node = rootToUse.browseTree(quadLocation)
            print("LiveMomentStore did  browse tree result node: \(node?.getTreeId() ?? "no result")")
            compute()
            isWorking = false
            result = node
            self.save(false, result)

        } else {
            isWorking = false
        }
      return result
    }


    internal func getClustersInBase() ->  QuadTreeNode? {
        let start = CFAbsoluteTimeGetCurrent()
        print("LiveMomentStore - getClustersInBase start")
        let result = dataBase.getQuadTreeRoot()
        let end = CFAbsoluteTimeGetCurrent()
        let elapsedTime = (end - start) * 1000
        print("LiveMomentStore - getClustersInBase took in \(elapsedTime) ms ")
        return result
    }

    internal  func getNodeForId(_ id: String) ->  QuadTreeNode?  {
        var result :  QuadTreeNode?
        if let root = self.root  {
            result = root.findNodeWithId(id)
        }
        return result
    }


    internal func computeRects()  {
        self.rects =  self.root?.getReccursiveRects(nil)
    }

    internal func computeHome() -> QuadTreeNode? {
        let nodes = getRects()?.filter {
            $0.locations.count > 10 &&
            ($0.densities?.count ?? 0)  > 0 &&
            $0.densities?[LivingTag.home.rawValue] ?? 0 > 0
            
        }.sorted {
           return $0.densities?[LivingTag.home.rawValue] ?? 0 < $1.densities?[LivingTag.home.rawValue] ?? 0
        }

        return  nodes?.first?.node

    }

    internal func compute() {
        
        DispatchQueue.global(qos: .background).async {

            let start = CFAbsoluteTimeGetCurrent()
            print("LiveMomentStore - compute start")
            self.computeRects()
            self.work = self.computeWork()
            self.home = self.computeHome()
            self.school = self.computeSchool()
            self.shoppings = self.computeShopping()
            self.others = nil
          //  DispatchQueue.main.async {
                for listener in self.listeners {
                    listener.get()?.didCompute(rects: self.rects, home: self.home, work:  self.work, school: self.school, shoppings: self.shoppings, others: self.others)
                }
         //   }

            let end = CFAbsoluteTimeGetCurrent()
            let elapsedTime = (end - start) * 1000
            print("LiveMomentStore - compute took in \(elapsedTime) ms ")
        }
    }

    internal func computeWork() -> QuadTreeNode? {
        let nodes = getRects()?.filter {
            $0.locations.count > 10 &&
            ($0.densities?.count ?? 0)  > 0 &&
            $0.densities?[LivingTag.work.rawValue] ?? 0 > 0

        }.sorted {
          return  $0.densities?[LivingTag.work.rawValue] ?? 0 < $1.densities?[LivingTag.work.rawValue] ?? 0
        }
        return  nodes?.first?.node

    }

    internal func computeSchool() -> QuadTreeNode? {
        let nodes = getRects()?.filter {
            $0.locations.count > 10 &&
            ($0.densities?.count ?? 0)  > 0 &&
            $0.densities?[LivingTag.school.rawValue] ?? 0 > 0

        }.sorted {
          return  $0.densities?[LivingTag.school.rawValue] ?? 0 < $1.densities?[LivingTag.school.rawValue] ?? 0
        }
        return  nodes?.first?.node
    }

    internal func computeShopping() -> [QuadTreeNode]? {
        let nodes = getRects()?.filter {

            ($0.densities?.count ?? 0)  > 0 &&
            $0.densities?[LivingTag.shopping.rawValue] ?? 0 > 0
        }
        return nodes?.map {
            return $0.node
        }.filter {
           return  $0.getRect().circle().radius <  2 * StorageConstants.shoppingMinRadius
        }
    }

}
