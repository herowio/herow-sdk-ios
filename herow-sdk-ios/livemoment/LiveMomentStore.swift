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

    func liveMomentStoreStartComputing()
    func  didCompute( rects: [NodeDescription]?, home: QuadTreeNode?, work: QuadTreeNode?, school: QuadTreeNode?, shoppings: [QuadTreeNode]?, others: [QuadTreeNode]?, neighbours:[QuadTreeNode]?, periods:[PeriodProtocol])
    func didChangeNode(node: QuadTreeNode )
}

protocol LiveMomentStoreProtocol: DetectionEngineListener, AppStateDelegate, CacheListener {
    init(db: DataBase, storage: HerowDataStorageProtocol)
    func getNodeForLocation(_ location: CLLocation, completion: @escaping (Bool)->())
    func getClusters() ->  QuadTreeNode?
    func getNodeForId(_ id: String) ->  QuadTreeNode?
    func getParentForNode(_ node: QuadTreeNode) -> QuadTreeNode?
    func getHome() -> QuadTreeNode?
    func getWork() -> QuadTreeNode?
    func getSchool() -> QuadTreeNode?
    func getShopping() -> [QuadTreeNode]?
    func registerLiveMomentStoreListener(_ listener: LiveMomentStoreListener )
    func processOnlyOnCurrentGeoHash(_ value: Bool)
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
    private var periods: [PeriodProtocol] = [PeriodProtocol]()
    private var needGetPeriods = true
    private var onGeoHashOnly: Bool = false

    required init(db: DataBase, storage: HerowDataStorageProtocol) {
        self.dataBase = db
        self.dataStorage = storage
        queue.qualityOfService = .background
        queue.maxConcurrentOperationCount = 1
        self.loadTree()
    }

    func loadTree() {
        let start = CFAbsoluteTimeGetCurrent()
        self.dataBase.createQuadTreeRoot {
            let endRoot = CFAbsoluteTimeGetCurrent()
            var  elapsedTime = (endRoot - start) * 1000
            GlobalLogger.shared.debug("LiveMomentStore createQuadTreeRoot took \(elapsedTime) ms ")
            self.root = self.getClustersInBase()
            let end = CFAbsoluteTimeGetCurrent()
            elapsedTime = (end - start) * 1000
            self.compute()
        }
    }

    func processOnlyOnCurrentGeoHash(_ value: Bool) {
        if (onGeoHashOnly != value) {
            onGeoHashOnly = value
            compute()
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

        self.currentNode = nil
        backgroundQueue.async {
            //new pois you need to reload tree with this pois
           self.loadTree()
        }
    }

    func willCacheUpdate() {
    }

    func onLocationUpdate(_ location: CLLocation, from: UpdateType) {

        let now = Date()
        self.needGetPeriods = true
        if  (self.periods.filter { $0.end > now}.first != nil) {
            self.needGetPeriods = false
        }
        if self.root == nil || isWorking   {
            GlobalLogger.shared.debug("LiveMomentStore - isWorking")
            return
        }
        let start = CFAbsoluteTimeGetCurrent()
        GlobalLogger.shared.debug("LiveMomentStore - onLocationUpdate start")
        isWorking = true
        let blockOPeration = BlockOperation { [self] in
            if self.backgroundTaskId == .invalid {
                self.backgroundTaskId = UIApplication.shared.beginBackgroundTask(
                    withName: "herow.io.LiveMomentStore.backgroundTaskID",
                    expirationHandler: {
                        if self.backgroundTaskId != .invalid {
                            UIApplication.shared.endBackgroundTask(self.backgroundTaskId)
                            self.backgroundTaskId = .invalid
                            GlobalLogger.shared.info("LiveMomentStore ends backgroundTask with identifier : \( self.backgroundTaskId)")
                        }
                    })
            }
            GlobalLogger.shared.info("LiveMomentStore starts backgroundTask with identifier : \( self.backgroundTaskId)")
            self.getNodeForLocation(location, completion: { working in
                var end = CFAbsoluteTimeGetCurrent()
                var elapsedTime = (end - start) * 1000
                GlobalLogger.shared.debug("LiveMomentStore - onLocationUpdate done in \(elapsedTime) ms  ")
                self.compute()
                isWorking = working
                 end = CFAbsoluteTimeGetCurrent()
                 elapsedTime = (end - start) * 1000
                GlobalLogger.shared.debug("LiveMomentStore - compute done in \(elapsedTime) ms  ")
                if self.backgroundTaskId != .invalid {
                    UIApplication.shared.endBackgroundTask(self.backgroundTaskId)
                    self.backgroundTaskId = .invalid
                    GlobalLogger.shared.info("LiveMomentStore ends backgroundTask with identifier : \( self.backgroundTaskId)")
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
        if let root = self.root {
            isSaving = true
            let nodeToSave = node ?? root
            dataBase.saveQuadTree(nodeToSave) {
                nodeToSave.setLastLocation(nil)
                self.isSaving = false
                self.count = 0
                completion()
            }
        }
    }

    internal func reverseExploration(node: QuadTreeNode, location: QuadTreeLocation) -> QuadTreeNode? {
        if node.getRect().contains(location) {
            return node
        } else {
            if let parent = node.getParentNode() {
                return reverseExploration(node: parent, location: location)
            }
        }
        return self.root
    }

    internal  func getNodeForLocation(_ location: CLLocation, completion: @escaping (Bool)->())  {
        for listener in self.listeners {
            listener.get()?.liveMomentStoreStartComputing()
        }
        backgroundQueue.async {
            var result : QuadTreeNode?
            let quadLocation = HerowQuadTreeLocation(lat: location.coordinate.latitude, lng: location.coordinate.longitude, time: location.timestamp)
            if let nodeToUse =  self.currentNode ?? self.root {
                var start = CFAbsoluteTimeGetCurrent()
                let rootToUse:QuadTreeNode? = self.reverseExploration(node: nodeToUse, location: quadLocation)
                var end = CFAbsoluteTimeGetCurrent()
                var elapsedTime = (end - start) * 1000
                GlobalLogger.shared.debug("LiveMomentStore -  reverseExploration took \(elapsedTime) ms  ")
                if let rootToUse = rootToUse {
                     start = CFAbsoluteTimeGetCurrent()
                    GlobalLogger.shared.debug("LiveMomentStore - browseTree start")
                    let node = rootToUse.browseTree(quadLocation)
                     end = CFAbsoluteTimeGetCurrent()
                    elapsedTime = (end - start) * 1000
                    GlobalLogger.shared.debug("LiveMomentStore - browseTree result node: \(rootToUse.getTreeId()) in \(elapsedTime) ms  ")
                    start = CFAbsoluteTimeGetCurrent()
                    result = node?.addLocation(quadLocation)
                    end = CFAbsoluteTimeGetCurrent()
                     elapsedTime = (end - start) * 1000
                    GlobalLogger.shared.debug("LiveMomentStore - add location  result node: \(rootToUse.getTreeId()) in \(elapsedTime) ms  ")

                    let nodeToSave = result?.getParentNode() ?? result
                    self.currentNode = result
                    if let node = self.currentNode {
                        for listener in self.listeners {
                            listener.get()?.didChangeNode(node: node)
                        }
                    }
                     start = CFAbsoluteTimeGetCurrent()
                    self.save(false, nodeToSave) {
                        result?.setUpdated(false)
                        nodeToSave?.setUpdated(false)
                        self.computePeriods(quadLocation)
                        end = CFAbsoluteTimeGetCurrent()
                        elapsedTime = (end - start) * 1000
                        GlobalLogger.shared.debug("LiveMomentStore - browseTree save took \(elapsedTime) ms  ")
                        completion(false)
                    }
                    GlobalLogger.shared.debug("LiveMomentStore - tree result node: \(result?.getTreeId() ?? "none") location count: \(result?.getLocations().count ?? 0) ")

                } else {
                    completion(false)
                }
            } else {
                completion(false)
            }
        }
    }

    internal func computePeriods( _ location: QuadTreeLocation) {
        let start = CFAbsoluteTimeGetCurrent()
        for p in periods {
            var period = p
            period.addLocation(location)
        }
        let end = CFAbsoluteTimeGetCurrent()
        let elapsedTime = (end - start) * 1000
        GlobalLogger.shared.debug("LiveMomentStore - computePeriods took in \(elapsedTime) ms ")
    }

    internal func getClustersInBase() ->  QuadTreeNode? {
        let start = CFAbsoluteTimeGetCurrent()
        GlobalLogger.shared.debug("LiveMomentStore - getClustersInBase start")
        let result = dataBase.getQuadTreeRoot()
        let end = CFAbsoluteTimeGetCurrent()
        let elapsedTime = (end - start) * 1000
        GlobalLogger.shared.debug("LiveMomentStore - getClustersInBase took in \(elapsedTime) ms ")
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
        self.root = self.getClustersInBase()
        self.rects =  self.root?.getReccursiveRects(nil)
    }

    internal func compute() {
        backgroundQueue.async {
            let start = CFAbsoluteTimeGetCurrent()
            GlobalLogger.shared.debug("LiveMomentStore - compute start")
            self.computeRects()
            let candidates = self.getNodeCandidates()
            self.work = self.computeWork(candidates)
            self.home = self.computeHome(candidates)
            self.school = self.computeSchool(candidates)
            self.shoppings = self.computeShopping(candidates)
            self.others = nil
            let neighbours =  self.currentNode?.neighbours()
            let computeBlock: ([PeriodProtocol])-> () = { periods in
                let end = CFAbsoluteTimeGetCurrent()

                for listener in self.listeners {
                    listener.get()?.didCompute(rects: self.rects, home: self.home, work:  self.work, school: self.school, shoppings: self.shoppings, others: self.others, neighbours: neighbours, periods: periods)
                }
                let elapsedTime = (end - start) * 1000
                GlobalLogger.shared.debug("LiveMomentStore - compute took in \(elapsedTime) ms ")
            }
            if self.needGetPeriods {
                GlobalLogger.shared.debug("LiveMomentStore - get periods start")
                self.dataBase.getPeriods { periods in
                    let end = CFAbsoluteTimeGetCurrent()
                    let elapsedTime = (end - start) * 1000
                    GlobalLogger.shared.debug("LiveMomentStore - get periods took in \(elapsedTime) ms ")
                    self.periods = periods
                    computeBlock(periods)
                }
            } else {
                computeBlock(self.periods)
            }
        }
    }

    internal func getNodeCandidates() -> [NodeDescription]? {

        var nodes = getRects()?.filter {
            $0.locations.count > 10 }
        if let currentGeoHash = HerowInitializer.instance.getLastGeoHash(),  let geohash = Geohash.decode(hash: currentGeoHash)  {
            if onGeoHashOnly {
                nodes = nodes?.filter{
                    $0.rect.originLat >= geohash.latitude.min &&
                    $0.rect.endLat <= geohash.latitude.max &&
                    $0.rect.originLng >= geohash.longitude.min &&
                    $0.rect.endLng <= geohash.longitude.max
                }
            }
        }
        return  nodes
    }

    internal func computeHome( _ candidates: [NodeDescription]?) -> QuadTreeNode? {
        let nodes = candidates?.filter {
            ($0.densities?.count ?? 0)  > 0 &&
            $0.densities?[LivingTag.home.rawValue] ?? 0 > 0
        }.sorted {
            return $0.densities?[LivingTag.home.rawValue] ?? 0 < $1.densities?[LivingTag.home.rawValue] ?? 0
        }
        let home =  nodes?.first?.node
        return  home
    }

    internal func computeWork(_ candidates: [NodeDescription]?) -> QuadTreeNode? {
        let nodes = candidates?.filter {
            ($0.densities?.count ?? 0)  > 0 &&
            $0.densities?[LivingTag.work.rawValue] ?? 0 > 0
        }.sorted {
            return  $0.densities?[LivingTag.work.rawValue] ?? 0 < $1.densities?[LivingTag.work.rawValue] ?? 0
        }
        return  nodes?.first?.node
    }

    internal func computeSchool(_ candidates: [NodeDescription]?) -> QuadTreeNode? {
        let nodes = candidates?.filter {
            ($0.densities?.count ?? 0)  > 0 &&
            $0.densities?[LivingTag.school.rawValue] ?? 0 > 0
        }.sorted {
            return  $0.densities?[LivingTag.school.rawValue] ?? 0 < $1.densities?[LivingTag.school.rawValue] ?? 0
        }
        return  nodes?.first?.node
    }

    internal func computeShopping(_ candidates: [NodeDescription]?) -> [QuadTreeNode]? {
        let nodes = candidates?.map {$0.node}.filter{$0.isNearToPoi() }
        return nodes
    }
}
