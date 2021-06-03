//
//  CoreDataManager.swift
//  herow-sdk-ios
//
//  Created by Damien on 25/01/2021.
//

import Foundation
import CoreData

class CoreDataManager<Z: Zone, A: Access,P: Poi,C: Campaign, N: Notification, Q: Capping,T: QuadTreeNode, L: QuadTreeLocation>: DataBase {

    lazy var persistentContainer: NSPersistentContainer = {
        let messageKitBundle = Bundle(for: Self.self)
        let modelURL = messageKitBundle.url(forResource: StorageConstants.dataModelName, withExtension: "momd")!
        let managedObjectModel =  NSManagedObjectModel(contentsOf: modelURL)
        let container = NSPersistentContainer(name: StorageConstants.dataModelName, managedObjectModel: managedObjectModel!)
        container.loadPersistentStores { (storeDescription, error) in
            if let err = error{
                fatalError("❌ Loading of store failed:\(err)")
            }
        }
        return container
    }()

    lazy var context: NSManagedObjectContext = {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.parent = bgContext
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }()

    lazy var bgContext: NSManagedObjectContext  = {
        let ct = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        ct.persistentStoreCoordinator = persistentContainer.persistentStoreCoordinator
        ct.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return ct
    }()

    // MARK: - Core Data read and write

    func savePoisInBase(items: [Poi], completion: (()->())? = nil) {
        self.bgContext.perform {
            for item in items {
                var  poiCoreData :PoiCoreData?
                let fetchRequest =
                    NSFetchRequest<PoiCoreData>(entityName: StorageConstants.PoiCoreDataEntityName)
                fetchRequest.predicate = NSPredicate(format: "\(StorageConstants.id) == %@", item.getId())
                poiCoreData = try?  self.bgContext.fetch(fetchRequest).first
                if poiCoreData == nil {
                    let entity =
                        NSEntityDescription.entity(forEntityName: StorageConstants.PoiCoreDataEntityName,
                                                   in:  self.bgContext)!
                    poiCoreData = PoiCoreData(entity: entity,
                                              insertInto:  self.bgContext)
                }
                poiCoreData?.id = item.getId()
                poiCoreData?.lat = item.getLat()
                poiCoreData?.lng = item.getLng()
                poiCoreData?.tags = item.getTags()
            }
            self.save(completion)
        }
    }

    func saveCampaignsInBase(items: [Campaign],  completion: (()->())? = nil) {
        self.bgContext.perform {
            for item in items {
                var campaignCoreData: CampaignCoreData?
                let  fetchRequest =
                    NSFetchRequest<CampaignCoreData>(entityName: StorageConstants.CampaignCoreDataEntityName)
                fetchRequest.predicate = NSPredicate(format: "\(StorageConstants.id) == %@", item.getId())
                campaignCoreData = try? self.bgContext.fetch(fetchRequest).first
                if campaignCoreData == nil {
                    let entity =
                        NSEntityDescription.entity(forEntityName: StorageConstants.CampaignCoreDataEntityName,
                                                   in: self.bgContext)!
                    campaignCoreData = CampaignCoreData(entity: entity,
                                                        insertInto: self.bgContext)
                }
                campaignCoreData?.id = item.getId()
                campaignCoreData?.name = item.getName()
                campaignCoreData?.begin = item.getBegin()
                campaignCoreData?.end = item.getEnd() ?? 0
                campaignCoreData?.startHour = item.getStartHour() ?? ""
                campaignCoreData?.stopHour = item.getStopHour() ?? ""
                campaignCoreData?.cappings = item.getCappings() ?? [String: Int]()
                campaignCoreData?.daysRecurrence = item.getDaysRecurrence() ?? [String]()
                var notificationCoreData: NotificationCoreData?
                if let notification = item.getNotification() {
                    let entity = NSEntityDescription.entity(forEntityName: StorageConstants.NotificationCoreDataEntityName,
                                                            in: self.bgContext)!
                    notificationCoreData = NotificationCoreData(entity: entity,
                                                                insertInto: self.bgContext)
                    notificationCoreData?.title = notification.getTitle()
                    notificationCoreData?.content = notification.getDescription()
                    notificationCoreData?.image = notification.getImage() ?? ""
                    notificationCoreData?.thumbnail = notification.getThumbnail() ?? ""
                    notificationCoreData?.uri = notification.getUri() ?? ""
                }
                if let notificationCoreData = notificationCoreData {
                    campaignCoreData?.notification = notificationCoreData
                }
            }
            self.save(completion)
        }
    }

    func saveZonesInBase(items: [Zone], completion: (()->())? = nil) {
        self.bgContext.perform {
            for item in items {
                var  zoneCoreData :ZoneCoreData?
                let fetchRequest =
                    NSFetchRequest<ZoneCoreData>(entityName: StorageConstants.ZoneCoreDataEntityName)
                fetchRequest.predicate = NSPredicate(format: "\(StorageConstants.zoneHash) == %@", item.getHash())
                zoneCoreData = try?  self.bgContext.fetch(fetchRequest).first
                if zoneCoreData == nil {
                    let entity =
                        NSEntityDescription.entity(forEntityName: StorageConstants.ZoneCoreDataEntityName,
                                                   in:  self.bgContext)!
                    zoneCoreData = ZoneCoreData(entity: entity,
                                                insertInto:  self.bgContext)
                }
                zoneCoreData?.zoneHash = item.getHash()
                var accessInBase =  zoneCoreData?.access
                GlobalLogger.shared.debug("CoreDataManager:  access in base : \(String(describing: accessInBase))")
                if accessInBase  == nil {
                    let entity =
                        NSEntityDescription.entity(forEntityName: StorageConstants.AccessCoreDataEntityName,
                                                   in:  self.bgContext)!
                    accessInBase = AccessCoreData(entity: entity,
                                                  insertInto:  self.bgContext)
                }
                if let access = item.getAccess() {
                    GlobalLogger.shared.debug("CoreDataManager:  zone has access")
                    GlobalLogger.shared.debug("CoreDataManager: access : \(access.getName())")
                    GlobalLogger.shared.debug("CoreDataManager: access : \(access.getAddress())")
                    accessInBase?.id = access.getId()
                    accessInBase?.name = access.getName()
                    accessInBase?.address = access.getAddress()
                } else {
                    GlobalLogger.shared.debug("CoreDataManager:  zone has no access")
                }
                if let accessInBase = accessInBase {
                    zoneCoreData?.access = accessInBase
                }
                GlobalLogger.shared.debug("CoreDataManager:  access name : \(String(describing: zoneCoreData?.access.name))")
                zoneCoreData?.lat = item.getLat()
                zoneCoreData?.lng = item.getLng()
                zoneCoreData?.radius = item.getRadius()
                zoneCoreData?.zoneHash = item.getHash()
                zoneCoreData?.campaigns = item.getCampaigns()
            }
            self.save(completion)
        }
    }

    func getZonesInBase() -> [Zone] {
        return getZonesInBase(nil)
    }

    func getZonesInBase(_ idList: [String]? = nil) -> [Zone] {
        var zones = [Zone]()
        var context = self.bgContext
        if Thread.isMainThread {
            // print("getZonesInBase MAIN THREAD ! ")
            context = self.context
        }
        context.performAndWait() {
            zones =  _getZonesInBase(idList, context: context)
        }
        return zones
    }

    private  func _getZonesInBase(_ idList: [String]? = nil, context: NSManagedObjectContext) -> [Zone] {
        var zones = [Zone]()
        let managedContext = context
        let fetchRequest = NSFetchRequest<ZoneCoreData>(entityName: StorageConstants.ZoneCoreDataEntityName)
        if let idList = idList {
            fetchRequest.predicate = NSPredicate(format: "zoneHash IN %@", idList)
        }
        do {
            let  zonesCoreData = try managedContext.fetch(fetchRequest)
            for zoneCoreData in zonesCoreData {
                let hash = zoneCoreData.zoneHash
                let lat = zoneCoreData.lat
                let lng = zoneCoreData.lng
                let radius = zoneCoreData.radius
                let campaigns = zoneCoreData.campaigns as [String]
                let access = A(id: zoneCoreData.access.id,
                               name: zoneCoreData.access.name,
                               address: zoneCoreData.access.address)
                let zone: Z = Z(hash: hash, lat:lat, lng: lng, radius: radius, campaigns: campaigns, access: access)
                zones.append(zone)
            }
        }
        catch let error as NSError {
             print("Could not fetch. \(error), \(error.userInfo)")
        }
        return zones
    }

    func getCampaignsInBase() -> [Campaign] {
        var campaigns = [Campaign]()
        var context = self.bgContext
        if Thread.isMainThread {
            // print("MAIN THREAD ! ")
            context = self.context
        }
        context.performAndWait {
            campaigns =  _getCampaignsInBase(context: context)
        }
        return campaigns
    }

    private  func _getCampaignsInBase(context: NSManagedObjectContext) -> [Campaign] {
        var campaigns = [Campaign]()
        let managedContext = context
        let fetchRequest = NSFetchRequest<CampaignCoreData>(entityName: StorageConstants.CampaignCoreDataEntityName)
        do {
            let  campaignsCoreData = try managedContext.fetch(fetchRequest)
            for campaignsCoreData in campaignsCoreData {
                let id = campaignsCoreData.id
                let name = campaignsCoreData.name
                let begin = campaignsCoreData.begin
                let end = campaignsCoreData.end
                let cappings = campaignsCoreData.cappings
                let daysRecurrence = campaignsCoreData.daysRecurrence
                let startHour = campaignsCoreData.startHour
                let stopHour = campaignsCoreData.stopHour
                let  notification = N(title: campaignsCoreData.notification.title, description: campaignsCoreData.notification.content,image: campaignsCoreData.notification.image, thumbnail: campaignsCoreData.notification.thumbnail,textToSpeech: campaignsCoreData.notification.textToSpeech, uri : campaignsCoreData.notification.uri)
                let campaign = C(id: id, name: name, begin: begin, end: end, cappings: cappings, daysRecurrence: daysRecurrence, notification: notification, startHour: startHour, stopHour: stopHour)
                campaigns.append(campaign)
            }
        }
        catch let error as NSError {
             print("Could not fetch. \(error), \(error.userInfo)")
        }
        return campaigns
    }

    func getCapping(id: String) -> Capping? {
        var capping: Capping?
        var context = self.bgContext
        if Thread.isMainThread {
            // print("MAIN THREAD ! ")
            context = self.context
        }
        context.performAndWait {
            capping =  _getCapping(id: id, context: context)
        }
        return capping
    }

    private  func _getCapping(id: String, context: NSManagedObjectContext) -> Capping? {
        var capping: Capping?
        let managedContext = context
        let fetchRequest = NSFetchRequest<CappingCoreData>(entityName: StorageConstants.CappingCoreDataEntityName)
        fetchRequest.predicate = NSPredicate(format: "\(StorageConstants.campaignId) == %@", id)
        do {
            if let  cappingCoreData = try managedContext.fetch(fetchRequest).first {
                let id = cappingCoreData.campaignId
                let razDate = cappingCoreData.razDate
                let count = cappingCoreData.count
                capping = Q(id: id, razDate: razDate, count: count)
            }
        }
        catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        return capping
    }

    func saveCapping(_ capping: Capping, completion: (()->())? = nil) {
        var context = self.bgContext
        if Thread.isMainThread {
            // print("MAIN THREAD ! ")
            context = self.context
        }
        context.performAndWait {
            var  cappingCoreData :CappingCoreData?
            let fetchRequest =
                NSFetchRequest<CappingCoreData>(entityName: StorageConstants.CappingCoreDataEntityName)
            fetchRequest.predicate = NSPredicate(format: "\(StorageConstants.campaignId) == %@", capping.getId())
            cappingCoreData = try? bgContext.fetch(fetchRequest).first
            if cappingCoreData == nil {
                let entity =
                    NSEntityDescription.entity(forEntityName: StorageConstants.CappingCoreDataEntityName,
                                               in: bgContext)!
                cappingCoreData = CappingCoreData(entity: entity,
                                                  insertInto: bgContext)
            }
            cappingCoreData?.campaignId = capping.getId()
            cappingCoreData?.razDate = capping.getRazDate()
            cappingCoreData?.count = capping.getCount()
            save() {
                completion?()
            }
        }
    }

    func getPoisInBase() -> [Poi] {
        var pois = [Poi]()
        self.context.performAndWait {
            pois = _getPoisInBase()
        }
        return pois
    }

    private  func _getPoisInBase() -> [Poi] {
        var pois = [Poi]()
        let managedContext = context
        let fetchRequest = NSFetchRequest<PoiCoreData>(entityName: StorageConstants.PoiCoreDataEntityName)
        do {
            let  poisCoreData = try managedContext.fetch(fetchRequest)
            for poiCoreData in poisCoreData {
                pois.append(createPoiObject(poiCoreData))
            }
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        return pois
    }

    private  func getPoisCoreData() -> [PoiCoreData] {
        var pois = [PoiCoreData]()
        var context = self.bgContext
        if Thread.isMainThread {
            // print("MAIN THREAD ! ")
            context = self.context
        }
        pois = _getPoisCoreData(context: context)
        return pois
    }

    private func _getPoisCoreData(context: NSManagedObjectContext) -> [PoiCoreData] {
        let managedContext = context
        var pois = [PoiCoreData]()
        let fetchRequest = NSFetchRequest<PoiCoreData>(entityName: StorageConstants.PoiCoreDataEntityName)
        context.performAndWait {
            do {
                let  poisCoreData = try managedContext.fetch(fetchRequest)
                pois =  Array(poisCoreData)
            } catch let error as NSError {
                print("Could not fetch. \(error), \(error.userInfo)")
            }}
        return pois
    }

    func getPoiCoreData( id: String, context: NSManagedObjectContext) -> PoiCoreData? {
        let managedContext = context
        var poi: PoiCoreData?
        let fetchRequest = NSFetchRequest<PoiCoreData>(entityName: StorageConstants.PoiCoreDataEntityName)
        fetchRequest.predicate = NSPredicate(format: "\(StorageConstants.id) == %@", id)
        context.performAndWait {
            do {
                let  poisCoreData = try managedContext.fetch(fetchRequest)
                poi =  poisCoreData.first
            }
            catch let error as NSError {
                print("Could not fetch. \(error), \(error.userInfo)")
            }
        }
        return poi
    }

    func createPoiObject(_ poiCoreData: PoiCoreData) -> Poi {
        let poi: P = P(id: poiCoreData.id, tags: poiCoreData.tags, lat: poiCoreData.lat, lng: poiCoreData.lng)
        return poi
    }

    func getNearbyPois(_ location: CLLocation, distance: CLLocationDistance, count: Int ) -> [Poi] {
        let pois = getPoisInBase().filter {
            let locationToCompare = CLLocation(latitude: $0.getLat(), longitude: $0.getLng())
            return location.distance(from: locationToCompare) <= distance
        }
        return Array(pois.sorted(by: {
            let locationToCompare1 = CLLocation(latitude: $0.getLat(), longitude: $0.getLng())
            let locationToCompare2 = CLLocation(latitude: $1.getLat(), longitude: $1.getLng())
            return location.distance(from: locationToCompare1) < location.distance(from: locationToCompare2)
        }).prefix(count))
    }

    func purgeAllData(completion: (()->())? = nil) {
        let uniqueNames = persistentContainer.managedObjectModel.entities.compactMap({ $0.name }).filter({$0 != StorageConstants.CappingCoreDataEntityName && $0 != StorageConstants.NodeCoreDataEntityName && $0 != StorageConstants.LocationCoreDataEntityName})
        uniqueNames.forEach { (name) in
            deleteEntitiesByName(name)
        }
        save(completion)
    }

    func deleteEntitiesByName(_ name: String) {
        self.bgContext.perform {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: name)
            // Create Batch Delete Request
            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            do {
                try  self.bgContext.execute(batchDeleteRequest)
            } catch {
                // print("error on delete")
            }
        }
    }

    func purgeCapping(completion: (()->())? = nil) {
        deleteEntitiesByName( StorageConstants.CappingCoreDataEntityName)
        save(completion)
    }

    private func save( _ completion: (() ->())? = nil) {
        DispatchQueue.global(qos: .background).async {
            self.context.performAndWait {
                if self.context.hasChanges {
                    do {
                        // print("saving main context")
                        try self.context.save()
                    } catch {
                        print ("Error saving main managed object context! \(error)")
                    }
                }
            }
            self.bgContext.perform {
                if self.bgContext.hasChanges {
                    do {
                        // print("saving bg context")
                        try self.bgContext.save()
                    } catch {
                        print ("Error saving bg managed object context! \(error)")
                    }
                }
            }
            completion?()
        }
    }

    //MARK: QUADTREE
    func saveQuadTree(_ node : QuadTreeNode,  completion: (()->())? = nil) {
        var context = self.bgContext
        if Thread.isMainThread {
            // print("MAIN THREAD ! ")
            context = self.context
        }
        self.context.perform {
            self.recursiveSave(node,context:  context)
            self.save(completion)
        }
    }

    func createQuadTreeRoot( completion: (()->())? = nil) {
        if getCoreDataQuadTreeRoot() != nil  {
            completion?()
            return
        }
        let pois = getPoisInBase()
        let root = T(id: "\(LeafType.root.rawValue)", locations: nil, leftUp: nil, rightUp: nil, leftBottom: nil, rightBottom: nil, tags: nil, densities: nil, rect: Rect.world, pois: pois)
        saveQuadTree(root) {
            completion?()
        }
    }

    func reloadNewPois(completion: (()->())? = nil) {
        var context = self.bgContext
         if Thread.isMainThread {
            // print("MAIN THREAD ! ")
            context = self.context
        }
        context.performAndWait {
            if  let root = self.getCoreDataQuadTreeRoot() {
                reloadPoisForNode(root)
            }
            self.save()
            completion?()
        }
    }

    func reloadPoisForNode(_ node: NodeCoreData, poisToSort: Set<PoiCoreData>? = nil) {
        var pois = poisToSort ??  Set(self.getPoisCoreData())
        if  let parent = node.parent {
            pois = parent.pois ?? Set<PoiCoreData>()
        }
        let  rect: Rect = Rect(originLat: node.originLat, endLat: node.endLat, originLng: node.originLng, endLng: node.endLng)
        let filteredArray =  pois.filter {
            let loc = L(lat: $0.lat, lng:  $0.lng, time: Date())
            return rect.contains(loc)
        }
        node.pois = Set(filteredArray)
        node.childs?.forEach { child in
            reloadPoisForNode(child, poisToSort: node.pois)
        }
    }

    private  func reCreateChildsForNode(_ node: NodeCoreData?, contextToUse: NSManagedObjectContext? = nil) -> NodeCoreData?  {
        var context = contextToUse
        if context == nil {
         context = self.bgContext
        if Thread.isMainThread {
            // print("MAIN THREAD ! ")
            context = self.context
        }
        }
        if let context = context {
        context.performAndWait {
            if  let id = node?.treeId {
                let child1 = reCreateChildsForNode(getCoreDataQuadTree("\(id)1", contextToUse: context), contextToUse: context)
                child1?.parent = node
                let child2 = reCreateChildsForNode(getCoreDataQuadTree("\(id)2", contextToUse: context), contextToUse: context)
                child2?.parent = node
                let child3 = reCreateChildsForNode(getCoreDataQuadTree("\(id)3", contextToUse: context), contextToUse: context)
                child3?.parent = node
                let child4 = reCreateChildsForNode(getCoreDataQuadTree("\(id)4", contextToUse: context), contextToUse: context)
                child4?.parent = node
                node?.childs = Set([child1, child2, child3, child4].compactMap{
                    return $0
                })
            }
        }
        }
        return node
    }

    private  func getCoreDataQuadTreeRoot() -> NodeCoreData? {
        return getCoreDataQuadTree("\(LeafType.root.rawValue)")
    }

    private  func getCoreDataQuadTree(_ id : String, contextToUse: NSManagedObjectContext? = nil) -> NodeCoreData? {
        let start = CFAbsoluteTimeGetCurrent()
        var result : NodeCoreData?
        var context = contextToUse
        if contextToUse == nil {
             context = self.bgContext
            if Thread.isMainThread {
                // print("MAIN THREAD ! ")
                context = self.context
            }
        }
        context?.performAndWait {
            let fetchRequest = NSFetchRequest<NodeCoreData>(entityName: StorageConstants.NodeCoreDataEntityName)
            fetchRequest.predicate = NSPredicate(format: "\(StorageConstants.treeId) == %@", id )
            do {
                let array = try context?.fetch(fetchRequest) ?? [NodeCoreData]()
                // print("LiveMomentStore -  getCoreDataQuadTreeRoot count : \(array.count) ")
                result = array.first

            } catch let error as NSError {
                print("Could not fetch. \(error), \(error.userInfo)")
            }
        }
        let endRoot = CFAbsoluteTimeGetCurrent()
        let  elapsedTime = (endRoot - start) * 1000
         print("LiveMomentStore -  find root in base took \(elapsedTime) ms ")
        return result
    }

    func getQuadTreeRoot() -> QuadTreeNode? {
        if let root =  getCoreDataQuadTreeRoot() {

            let quadTree  = recursiveInit(root)
          //  quadTree?.populateParentality()
            return quadTree
        }
        return nil
    }

    func  getNodeForId(_ id: String) -> QuadTreeNode? {
        var quadTree: QuadTreeNode?
        var context = self.bgContext
        if Thread.isMainThread {
            // print("MAIN THREAD ! ")
            context = self.context
        }
        context.performAndWait {
            quadTree = _getNodeForId(id, context: context)
        }
        return quadTree
    }

    private  func  _getNodeForId(_ id: String, context: NSManagedObjectContext) -> QuadTreeNode? {
        var node: QuadTreeNode?
        let fetchRequest = NSFetchRequest<NodeCoreData>(entityName: StorageConstants.NodeCoreDataEntityName)
        fetchRequest.predicate = NSPredicate(format: "\(StorageConstants.treeId) == %@", id)
        do {
            if let  nodeCoreData = try context.fetch(fetchRequest).first {
                node = recursiveInit(nodeCoreData)
            }
        }
        catch let error as NSError {
             print("Could not fetch. \(error), \(error.userInfo)")
        }
        return node
    }


    private func recursiveInit(_ node : NodeCoreData?)  -> QuadTreeNode?{
        guard let node = node else {
            return nil
        }

        var result : QuadTreeNode?
        var context = self.bgContext
        if Thread.isMainThread {
            // print("MAIN THREAD ! ")
            context = self.context
        }

        context.performAndWait {

            var mylocations = [L]()
            
            let  rect: Rect = Rect(originLat: node.originLat, endLat: node.endLat, originLng: node.originLng, endLng: node.endLng)
            var array : [PoiCoreData] =  [PoiCoreData]()

            if let fromParent = node.parent?.pois {
                print ("NODE \(node.treeId ) WITH PARENT \(node.parent?.treeId ?? "no parent") poi count: \(fromParent.count)")
                array = Array(fromParent)
            } else   if node.isRoot() {
                if let rootSet = node.pois  {
                    if rootSet.count > 0 {
                        array = Array(rootSet)
                    } else {
                        array = getPoisCoreData()
                    }
                } else {
                    array = getPoisCoreData()
                }
            }
            let filteredArray =  array.filter {
                let loc = L(lat: $0.lat, lng:  $0.lng, time: Date())
                return rect.contains(loc)
            }
            node.pois = Set(filteredArray)
            let pois = filteredArray.map {
                P(id: $0.id, tags: $0.tags, lat: $0.lat, lng: $0.lng)
            }
            if let coreDataLocations = node.locations {
                mylocations = coreDataLocations.map {L(lat: $0.lat, lng: $0.lng, time: $0.time)}
            }
            let treeId =  node.treeId
            let leftUp  = recursiveInit( node.leftUp())
            let rightUp  =  recursiveInit(node.rightUp())
            let leftBottom  =  recursiveInit(node.leftBottom())
            let rightBottom  =  recursiveInit(node.rightBottom())
            let tags = node.nodeTags
            let densities = node.nodeDensities
            if node.isRoot() {
                // print("ROOT CREATION")
            }
            if node.treeId == "021333" {
                // print("WTF ???")
            }


             result =  T(id:treeId, locations: mylocations, leftUp: leftUp, rightUp:rightUp, leftBottom: leftBottom, rightBottom: rightBottom, tags: tags,densities: densities, rect: rect, pois: pois)
            result?.getLeftUpChild()?.setParentNode(result)
            result?.getLeftBottomChild()?.setParentNode(result)
            result?.getRightUpChild()?.setParentNode(result)
            result?.getRightBottomChild()?.setParentNode(result)
        }
        return result
    }

    @discardableResult
    private func recursiveSave(_ node : QuadTreeNode?, context: NSManagedObjectContext ) -> NodeCoreData? {

        guard let node = node else {
            return nil
        }
        // print("NODE TO SAVE: \(node.getTreeId()) has \(node.childs().count) child(s)")
        var  nodeCoreData :NodeCoreData?
        context.performAndWait {
            let fetchRequest =
                NSFetchRequest<NodeCoreData>(entityName: StorageConstants.NodeCoreDataEntityName)
            fetchRequest.predicate = NSPredicate(format: "\(StorageConstants.treeId) == %@", node.getTreeId())
            nodeCoreData = try? context.fetch(fetchRequest).first
            if nodeCoreData == nil {
                let entity =
                    NSEntityDescription.entity(forEntityName: StorageConstants.NodeCoreDataEntityName,
                                               in: context)!
                nodeCoreData = NodeCoreData(entity: entity,
                                            insertInto: context)
                let pois = node.getPois()?.compactMap {
                    return getPoiCoreData(id: $0.getId(), context: context)
                } ?? [PoiCoreData]()
                nodeCoreData?.pois = Set(pois)
            }
            guard let nodeCoreData = nodeCoreData else {
                return
            }

            nodeCoreData.treeId = node.getTreeId()
            nodeCoreData.nodeTags = node.getDensities() ?? [String: Double]()
            nodeCoreData.nodeDensities = node.getDensities() ?? [String: Double]()
            nodeCoreData.originLat = node.getRect().originLat
            nodeCoreData.originLng = node.getRect().originLng
            nodeCoreData.endLat = node.getRect().endLat
            nodeCoreData.endLng = node.getRect().endLng
            let lastLocation = node.getLastLocation()
            if let newLocation = createLocation(lastLocation, context: context) {
                if  nodeCoreData.locations == nil {
                    // print("no locations")
                    nodeCoreData.locations = Set([LocationCoreData]())
                } else {

                }
                nodeCoreData.locations?.insert(newLocation)
            }

            let bottomLeftNode = node.getLeftBottomChild()
            let bottomRightNode = node.getRightBottomChild()
            let upRightNode = node.getRightUpChild()
            let upLeftNode = node.getLeftUpChild()
            var childToUpdate = [NodeCoreData]()


            if bottomLeftNode?.getUpdate() ?? false {
                let bottomLeft = recursiveSave(bottomLeftNode, context: context)
                bottomLeft?.type = "\(LeafType.leftBottom.rawValue)"
                bottomLeft?.parent = nodeCoreData
                if let node = bottomLeft {
                childToUpdate.append(node)
                }
            }

            if bottomRightNode?.getUpdate() ?? false {
                let bottomRight = recursiveSave(bottomRightNode, context: context)
                bottomRight?.type = "\(LeafType.rightBottom.rawValue)"
                bottomRight?.parent = nodeCoreData
                if let node = bottomRight {
                childToUpdate.append(node)
                }
            }

            if upRightNode?.getUpdate() ?? false {
                let upRight = recursiveSave(upRightNode, context: context)
                upRight?.type = "\(LeafType.rightUp.rawValue)"
                upRight?.parent = nodeCoreData
                if let node = upRight {
                childToUpdate.append(node)
                }
            }

            if upLeftNode?.getUpdate() ?? false {
                let upLeft = recursiveSave(upLeftNode, context: context)
                upLeft?.type = "\(LeafType.leftUp.rawValue)"
                upLeft?.parent = nodeCoreData
                if let node = upLeft {
                childToUpdate.append(node)
                }
            }
            if childToUpdate.count > 0 {
                var childToKeep =  Array(nodeCoreData.childs ?? Set([NodeCoreData]()))
                childToUpdate.forEach() { node in
                    childToKeep = childToKeep.filter {
                        return $0.treeId != node.treeId
                    }
                }
                childToUpdate.append(contentsOf: childToKeep)
                nodeCoreData.childs = Set(childToUpdate)
            }

            // print("NODE IN BASE \(nodeCoreData?.treeId ?? "Undefine") has \(nodeCoreData?.childs?.count ?? 0) child(s)")
        }
        return nodeCoreData
    }


    private func createLocation(_ location: QuadTreeLocation?, context:NSManagedObjectContext) -> LocationCoreData? {
        guard let location = location else {
            return nil
        }
        let entity =
            NSEntityDescription.entity(forEntityName: StorageConstants.LocationCoreDataEntityName,
                                       in: context)!
        let locationCoreData = LocationCoreData(entity: entity,
                                                insertInto: context)
        locationCoreData.lat = location.lat
        locationCoreData.lng = location.lng
        locationCoreData.time = location.time
        locationCoreData.isNearToPoi = location.isNearToPoi()
        return locationCoreData
    }

    @discardableResult
    private func saveLocations(_ locations: [QuadTreeLocation], context: NSManagedObjectContext ) -> Set<LocationCoreData> {
        var result = [LocationCoreData]()
        for loc in locations {
            let fetchRequest =
                NSFetchRequest<LocationCoreData>(entityName: StorageConstants.LocationCoreDataEntityName)
            fetchRequest.predicate = NSPredicate(format: "\(StorageConstants.locationLat) == %lf AND \(StorageConstants.locationLng) == %lf AND \(StorageConstants.locationTime) == %@", loc.lat, loc.lng, loc.time as NSDate)
            var  locationCoreData = try? context.fetch(fetchRequest).first
            if locationCoreData == nil {
                // print("saveLocations by creating")
                let entity =
                    NSEntityDescription.entity(forEntityName: StorageConstants.LocationCoreDataEntityName,
                                               in: context)!
                locationCoreData = LocationCoreData(entity: entity,
                                                    insertInto: context)
                locationCoreData?.lat = loc.lat
                locationCoreData?.lng = loc.lng
                locationCoreData?.time = loc.time
            }
            if let location = locationCoreData {
                result.append(location)
            }
        }
        return Set(result)
    }
}
