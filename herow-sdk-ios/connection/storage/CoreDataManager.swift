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

    var context: NSManagedObjectContext {
        return self.persistentContainer.viewContext
    }

    init() {
        self.createQuadTreeRoot()
    }

    lazy var bgContext: NSManagedObjectContext  = {
        let ct = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        ct.parent = context
        return ct
    }()

    // MARK: - Core Data read and write
    private func deleteEntity(name:String) {
        bgContext.performAndWait {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: name)
            fetchRequest.returnsObjectsAsFaults = false
            do {
                let results = try bgContext.fetch(fetchRequest)
                for managedObject in results {
                    if let managedObjectData: NSManagedObject = managedObject as? NSManagedObject {
                        bgContext.delete(managedObjectData)
                    }
                }
            } catch let error as NSError {
                print("Deleted all my data in myEntity error : \(error) \(error.userInfo)")
            }
        }

    }
    
    func savePoisInBase(items: [Poi], completion: (()->())? = nil) {
        bgContext.performAndWait {
            for item in items {
                var  poiCoreData :PoiCoreData?
                let fetchRequest =
                    NSFetchRequest<PoiCoreData>(entityName: StorageConstants.PoiCoreDataEntityName)
                fetchRequest.predicate = NSPredicate(format: "\(StorageConstants.id) == %@", item.getId())
                poiCoreData = try? bgContext.fetch(fetchRequest).first
                if poiCoreData == nil {
                    let entity =
                        NSEntityDescription.entity(forEntityName: StorageConstants.PoiCoreDataEntityName,
                                                   in: bgContext)!
                    poiCoreData = PoiCoreData(entity: entity,
                                              insertInto: bgContext)
                }
                poiCoreData?.id = item.getId()
                poiCoreData?.lat = item.getLat()
                poiCoreData?.lng = item.getLng()
                poiCoreData?.tags = item.getTags()
            }
        }
        save() {
            completion?()
        }
    }

    func saveCampaignsInBase(items: [Campaign],  completion: (()->())? = nil) {
        bgContext.performAndWait {
            for item in items {
                var campaignCoreData: CampaignCoreData?
                let  fetchRequest =
                    NSFetchRequest<CampaignCoreData>(entityName: StorageConstants.CampaignCoreDataEntityName)
                fetchRequest.predicate = NSPredicate(format: "\(StorageConstants.id) == %@", item.getId())
                campaignCoreData = try? bgContext.fetch(fetchRequest).first
                if campaignCoreData == nil {
                    let entity =
                        NSEntityDescription.entity(forEntityName: StorageConstants.CampaignCoreDataEntityName,
                                                   in: bgContext)!
                    campaignCoreData = CampaignCoreData(entity: entity,
                                                        insertInto: bgContext)
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
                                                            in: bgContext)!
                    notificationCoreData = NotificationCoreData(entity: entity,
                                                                insertInto: bgContext)
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
        }
        save() {
            completion?()
        }
    }

    func saveZonesInBase(items: [Zone], completion: (()->())? = nil) {
        bgContext.performAndWait {
            for item in items {
                var  zoneCoreData :ZoneCoreData?
                let fetchRequest =
                    NSFetchRequest<ZoneCoreData>(entityName: StorageConstants.ZoneCoreDataEntityName)
                fetchRequest.predicate = NSPredicate(format: "\(StorageConstants.zoneHash) == %@", item.getHash())
                zoneCoreData = try? bgContext.fetch(fetchRequest).first
                if zoneCoreData == nil {
                    let entity =
                        NSEntityDescription.entity(forEntityName: StorageConstants.ZoneCoreDataEntityName,
                                                   in: bgContext)!
                    zoneCoreData = ZoneCoreData(entity: entity,
                                                insertInto: bgContext)
                }
                zoneCoreData?.zoneHash = item.getHash()
                var accessInBase =  zoneCoreData?.access
                GlobalLogger.shared.debug("CoreDataManager:  access in base : \(String(describing: accessInBase))")
                if accessInBase  == nil {
                    let entity =
                        NSEntityDescription.entity(forEntityName: StorageConstants.AccessCoreDataEntityName,
                                                   in: bgContext)!
                    accessInBase = AccessCoreData(entity: entity,
                                                  insertInto: bgContext)
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
        }
        save() {
            completion?()
        }
    }

    func getZonesInBase() -> [Zone] {
        return getZonesInBase(nil)
    }

    func getZonesInBase(_ idList: [String]? = nil) -> [Zone] {
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
        bgContext.performAndWait {

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
        }
        save() {
            completion?()
        }
    }

    func getPoisInBase() -> [Poi] {
        var pois = [Poi]()
        let managedContext = context
        let fetchRequest = NSFetchRequest<PoiCoreData>(entityName: StorageConstants.PoiCoreDataEntityName)
        do {
            let  poisCoreData = try managedContext.fetch(fetchRequest)
            for poiCoreData in poisCoreData {
                let poi: P = P(id: poiCoreData.id, tags: poiCoreData.tags, lat: poiCoreData.lat, lng: poiCoreData.lng)
                pois.append(poi)
            }
        }
        catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        return pois
    }

    func purgeAllData(completion: (()->())? = nil) {
        let uniqueNames = persistentContainer.managedObjectModel.entities.compactMap({ $0.name }).filter({$0 != StorageConstants.CappingCoreDataEntityName && $0 != StorageConstants.NodeCoreDataEntityName && $0 != StorageConstants.LocationCoreDataEntityName})
        uniqueNames.forEach { (name) in
            deleteEntity(name: name)
        }
        save() {
            completion?()
        }
    }

    func purgeCapping(completion: (()->())? = nil) {
        deleteEntity(name: StorageConstants.CappingCoreDataEntityName)
        save() {
            completion?()
        }
    }

    private func save(completion: (() ->())? = nil) {
        saveContext(context: bgContext ) {
            DispatchQueue.main.async {
                self.saveContext(context: self.context) {
                    completion?()
                }
            }}

    }

    private func saveContext (context :NSManagedObjectContext, completion: (() ->())? = nil) {
        context.performAndWait {
            if context.hasChanges {
                do {
                    try context.save()
                } catch {
                    let nserror = error as NSError
                    fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
                }
            }
            completion?()
        }
    }

    //MARK: QUADTREE

    func saveQuadTree(_ node : QuadTreeNode,  completion: (()->())? = nil) {
        bgContext.performAndWait {
            recursiveSave(node,context: bgContext)
        }
        save() {
            completion?()
        }
    }

    func createQuadTreeRoot( completion: (()->())? = nil) {
        if hasQuadTreeRoot() {
            completion?()
            return
        }
        let root = T(id: "\(LeafType.root.rawValue)", locations: nil, leftUp: nil, rightUp: nil, leftBottom: nil, rightBottom: nil, tags: nil, rect: Rect.world)
        saveQuadTree(root) {
            completion?()
        }
    }

    func hasQuadTreeRoot() -> Bool {
        guard getQuadTreeRoot() != nil else {
            return false
        }
        return true
    }

    func getQuadTreeRoot() -> QuadTreeNode? {
        return getNodeForId( "\(LeafType.root.rawValue)")
    }

    func  getNodeForId(_ id: String) -> QuadTreeNode? {
        let managedContext = context
        var node: QuadTreeNode?
        let fetchRequest = NSFetchRequest<NodeCoreData>(entityName: StorageConstants.NodeCoreDataEntityName)
        fetchRequest.predicate = NSPredicate(format: "\(StorageConstants.treeId) == %@", id)
        do {
            if let  nodeCoreData = try managedContext.fetch(fetchRequest).first {
                node = recursiveInit(nodeCoreData)
            }
        }

        catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        return node
    }



    func recursiveInit(_ node : NodeCoreData?)  -> QuadTreeNode?{
        guard let node = node else {
            return nil
        }
        var mylocations = [L]()
        if let coreDataLocations = node.locations {
            for loc in coreDataLocations {
                mylocations.append(L(lat: loc.lat, lng: loc.lng, time: loc.time))
            }
        }
        let treeId =  node.treeId
        let leftUp  = recursiveInit( node.leftUp())
        let rightUp  =  recursiveInit(node.rightUp())
        let leftBottom  =  recursiveInit(node.leftBottom())
        let rightBottom  =  recursiveInit(node.rightBottom())
        let tags = node.nodeTags
        let  rect: Rect = Rect(originLat: node.originLat, endLat: node.endLat, originLng: node.originLng, endLng: node.endLng)
        return T(id:treeId, locations: mylocations, leftUp: leftUp, rightUp:rightUp, leftBottom: leftBottom, rightBottom: rightBottom, tags: tags, rect: rect )

    }

    @discardableResult
    func recursiveSave(_ node : QuadTreeNode?, context: NSManagedObjectContext ) -> NodeCoreData? {
        if let node = node {
            print("NODE TO SAVE has \(node.childs().count) child(s)")
        }
        guard let node = node else {
            return nil
        }
        var  nodeCoreData :NodeCoreData?
        let fetchRequest =
            NSFetchRequest<NodeCoreData>(entityName: StorageConstants.NodeCoreDataEntityName)
        fetchRequest.predicate = NSPredicate(format: "\(StorageConstants.treeId) == %@", node.getTreeId())
        nodeCoreData = try? bgContext.fetch(fetchRequest).first
        if nodeCoreData == nil {
            let entity =
                NSEntityDescription.entity(forEntityName: StorageConstants.NodeCoreDataEntityName,
                                           in: context)!
            nodeCoreData = NodeCoreData(entity: entity,
                                        insertInto: context)
        }
        nodeCoreData?.treeId = node.getTreeId()
        nodeCoreData?.nodeTags = node.getTags() ?? [String: Double]()
        nodeCoreData?.originLat = node.getRect().originLat
        nodeCoreData?.originLng = node.getRect().originLng
        nodeCoreData?.endLat = node.getRect().endLat
        nodeCoreData?.endLng = node.getRect().endLng
        nodeCoreData?.locations = saveLocations(node.getLocations(), context: context)
        let bottomLeft = recursiveSave(node.getLeftBottomChild(), context: context)
        bottomLeft?.type = "\(LeafType.leftBottom.rawValue)"
        let bottomRight = recursiveSave(node.getRightBottomChild(), context: context)
        bottomRight?.type = "\(LeafType.rightBottom.rawValue)"
        let upLeft = recursiveSave(node.getLeftUpChild(), context: context)
        upLeft?.type = "\(LeafType.leftUp.rawValue)"
        let upRight = recursiveSave(node.getRightUpChild(), context: context)
        upRight?.type = "\(LeafType.rightUp.rawValue)"
        let childs = [bottomLeft, bottomRight, upLeft, upRight].compactMap { $0 }
        nodeCoreData?.childs = Set(childs)
        
        print("NODE IN BASE has \(childs.count) child(s)")
        return nodeCoreData

    }

    @discardableResult
    func saveLocations(_ locations: [QuadTreeLocation], context: NSManagedObjectContext ) -> Set<LocationCoreData> {
        var result = [LocationCoreData]()
        for loc in locations {
            let entity =
                NSEntityDescription.entity(forEntityName: StorageConstants.LocationCoreDataEntityName,
                                           in: context)!
            let  locationCoreData = LocationCoreData(entity: entity,
                                                     insertInto: context)
            locationCoreData.lat = loc.lat
            locationCoreData.lng = loc.lng
            locationCoreData.time = loc.time
            result.append(locationCoreData)
        }

        return Set(result)
    }

}
