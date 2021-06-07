//
//  LiveMomentStore.swift
//  herow_sdk_ios
//
//  Created by Damien on 11/05/2021.
//

import Foundation
import CoreLocation
import UIKit

public protocol LiveMomentStoreListener {
    func  didCompute( rects: [NodeDescription]?, home: QuadTreeNode?, work: QuadTreeNode?, school: QuadTreeNode?, shoppings: [QuadTreeNode]?, others: [QuadTreeNode]?)
}

protocol LiveMomentStoreProtocol: DetectionEngineListener, AppStateDelegate, CacheListener {
    init(db: DataBase, storage: HerowDataStorageProtocol)
    func getNodeForLocation(_ location: CLLocation, completion: @escaping (Bool)->()) -> QuadTreeNode?
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
    private var backgroundTaskId: UIBackgroundTaskIdentifier =  UIBackgroundTaskIdentifier.invalid
    private var listeners = [WeakContainer<LiveMomentStoreListener>]()
    private let backgroundQueue =  DispatchQueue(label: "LiveMomentStoreQueue", qos: .background)
    private let queue = OperationQueue()
    required init(db: DataBase, storage: HerowDataStorageProtocol) {
        self.dataBase = db
        self.dataStorage = storage
        queue.qualityOfService = .background
        queue.maxConcurrentOperationCount = 1
        self.setup()

        
    }

    func setup() {
        let start = CFAbsoluteTimeGetCurrent()
        self.dataBase.createQuadTreeRoot {
            let endRoot = CFAbsoluteTimeGetCurrent()
            var  elapsedTime = (endRoot - start) * 1000
            print("LiveMomentStore createQuadTreeRoot took \(elapsedTime) ms ")
            self.root = self.getClustersInBase()
          /* self.root?.recursiveCompute()
            self.save {
                self.compute()
            }*/

            let end = CFAbsoluteTimeGetCurrent()
            elapsedTime = (end - start) * 1000
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

    }

    func onCacheUpdate(forGeoHash: String?) {

        guard forGeoHash != nil   else {
            return
        }

        let start = CFAbsoluteTimeGetCurrent()
         print("LiveMomentStore reloadNewPois ")
        backgroundQueue.async {
            self.dataBase.reloadNewPois {
                self.root = self.getClustersInBase()
                let end = CFAbsoluteTimeGetCurrent()
                let elapsedTime = (end - start) * 1000
                print("LiveMomentStore reloadNewPois took \(elapsedTime) ms ")
            }
        }
    }

    func willCacheUpdate() {
    }

    func onLocationUpdate(_ location: CLLocation, from: UpdateType) {
        if self.root == nil || isWorking   {
            return
        }

        let start = CFAbsoluteTimeGetCurrent()
        print("LiveMomentStore - onLocationUpdate start")



        isWorking = true
        let blockOPeration = BlockOperation { [self] in

            self.backgroundTaskId = UIApplication.shared.beginBackgroundTask(
                withName: "herow.io.LiveMomentStore.backgroundTaskID",
                expirationHandler: {
                    UIApplication.shared.endBackgroundTask(self.backgroundTaskId)
                    GlobalLogger.shared.verbose("LiveMomentStore ends backgroundTask with identifier : \( self.backgroundTaskId)")
                })
            GlobalLogger.shared.verbose("LiveMomentStore starts backgroundTask with identifier : \( self.backgroundTaskId)")
            self.currentNode = self.getNodeForLocation(location, completion: { working in
                self.compute()
                isWorking = working
                let end = CFAbsoluteTimeGetCurrent()
                let elapsedTime = (end - start) * 1000
                print("LiveMomentStore - onLocationUpdate done in \(elapsedTime) ms  ")
                DispatchQueue.main.async {
                    GlobalLogger.shared.verbose("LiveMomentStore ends backgroundTask with identifier : \( self.backgroundTaskId)")
                    UIApplication.shared.endBackgroundTask(self.backgroundTaskId)
                }
            })
            self.count = self.count + 1

        }



        queue.addOperation(blockOPeration)
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

    internal func save(_ force: Bool = false, _ node: QuadTreeNode? = nil , completion: @escaping ()->()) {
       // let lastSaveDate = self.dataStorage?.getLiveMomentLastSaveDate() ?? Date(timeIntervalSince1970: 0)
       let now = Date()
      //  let shouldSave = lastSaveDate.addingTimeInterval(600) < now || force || count > 5
        // print("LiveMomentStore  should save \(shouldSave)")
        if true {
            if let root = self.root {
                if isSaving {
                    // print("LiveMomentStore  will not save because isSaving : \(isSaving)")
                    completion()
                    return
                }
                isSaving = true

                let nodeToSave = node ?? root
                // print("LiveMomentStore  will save node: \(nodeToSave.getTreeId())")
                dataBase.saveQuadTree(nodeToSave) {
                    self.isSaving = false
                    self.dataStorage?.saveLiveMomentLastSaveDate(now)
                    // print("LiveMomentStore  did save node: \(nodeToSave.getTreeId())")
                    self.count = 0
                    completion()
                }
            }
        }
    }

    func reverseExploration(node: QuadTreeNode, location: QuadTreeLocation) -> QuadTreeNode? {
        if node.getRect().contains(location) {
            // print("LiveMomentStore reverseExploration for node :\(node.getTreeId())")
            return node
        } else {
            if let parent = node.getParentNode() {
                return reverseExploration(node: parent, location: location)
            }
        }
        return self.root
    }
    @discardableResult
    internal  func getNodeForLocation(_ location: CLLocation, completion: @escaping (Bool)->())  -> QuadTreeNode? {
        var result : QuadTreeNode?
        let quadLocation = HerowQuadTreeLocation(lat: location.coordinate.latitude, lng: location.coordinate.longitude, time: location.timestamp)
          if let nodeToUse =  self.currentNode ?? self.root {
            let rootToUse:QuadTreeNode? = reverseExploration(node: nodeToUse, location: quadLocation)
            if let rootToUse = rootToUse {
                // print("LiveMomentStore will  browse node: \(rootToUse.getTreeId())")



                let start = CFAbsoluteTimeGetCurrent()
                print("LiveMomentStore - browseTree start")
                let node = rootToUse.browseTree(quadLocation)
                result = node?.addLocation(quadLocation)
                let end = CFAbsoluteTimeGetCurrent()
                let elapsedTime = (end - start) * 1000
                print("LiveMomentStore - browseTree  result node: \(rootToUse.getTreeId()) in \(elapsedTime) ms  ")


                let nodeToSave = result?.getParentNode() ?? result
                self.currentNode = result
                self.save(false, nodeToSave) {
                    result?.setUpdated(false)
                    nodeToSave?.setUpdated(false)
                    completion(false)
                }
                 print("LiveMomentStore - tree result node: \(result?.getTreeId() ?? "none") location count: \(result?.getLocations().count ?? 0) ")
                return result
            } else {
                completion(false)
                return nil
            }
        } else {
            completion(false)
            return nil
        }


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
       // self.root = self.getClustersInBase()
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
        backgroundQueue.async {
            let start = CFAbsoluteTimeGetCurrent()
            print("LiveMomentStore - compute start")
            self.computeRects()
            self.work = self.computeWork()
            self.home = self.computeHome()
            self.school = self.computeSchool()
            self.shoppings = self.computeShopping()
            self.others = nil
            for listener in self.listeners {
                listener.get()?.didCompute(rects: self.rects, home: self.home, work:  self.work, school: self.school, shoppings: self.shoppings, others: self.others)
            }
            let end = CFAbsoluteTimeGetCurrent()
            let elapsedTime = (end - start) * 1000
            print("LiveMomentStore - compute done in \(elapsedTime) ms ")
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
        let result = nodes?.map {
            return $0.node
        }.filter {
            return  $0.getRect().circle().radius <= StorageConstants.shoppingMinRadius
        }
        return result
    }
}
