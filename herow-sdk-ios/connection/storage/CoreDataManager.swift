//
//  CoreDataManager.swift
//  herow-sdk-ios
//
//  Created by Damien on 25/01/2021.
//

import Foundation
import CoreData
import CoreLocation


class CoreDataManager<Z: Zone, A: Access,P: Poi,C: Campaign, N: Notification, Q: Capping>: DataBase {


    private  var  _persistentContainer: NSPersistentContainer?
    lazy var persistentContainer: NSPersistentContainer = {
        return getContainer()
    }()

    private func getContainer() -> NSPersistentContainer {
        let messageKitBundle = Bundle(for: Self.self)
        let modelURL = messageKitBundle.url(forResource: StorageConstants.dataModelName, withExtension: "momd")!
        let managedObjectModel =  NSManagedObjectModel(contentsOf: modelURL)
        _persistentContainer = NSPersistentContainer(name: StorageConstants.dataModelName, managedObjectModel: managedObjectModel!)
        reload(container: _persistentContainer)
        return _persistentContainer!
    }

    private func reload(container : NSPersistentContainer? ,_ retry: Bool = true) {
        let storeDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let url = storeDirectory.appendingPathComponent("\(StorageConstants.dataModelName).sqlite")
        let description = NSPersistentStoreDescription(url: url)
        description.shouldInferMappingModelAutomatically = true
        description.shouldMigrateStoreAutomatically = true
        description.setOption(FileProtectionType.none as NSObject, forKey: NSPersistentStoreFileProtectionKey)
        container?.persistentStoreDescriptions = [description]
        container?.loadPersistentStores { [unowned self] (storeDescription, error) in
            if let err = error{
               print("❌ Loading of store failed:\(err)")
                if retry {
                    self.deleteDB()
                }
            }
        }
    }

    private func deleteDB() {

        let storeDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let url = storeDirectory.appendingPathComponent("\(StorageConstants.dataModelName).sqlite")
        do {
            try _persistentContainer?.persistentStoreCoordinator.destroyPersistentStore(at: url, ofType: "sqlite", options: nil)
            reload(container:_persistentContainer, false)
        } catch {
            print("❌ deleteDB of store failed")
        }

    }

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
        let context = self.bgContext
      
        context.performAndWait {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: name)
            // Create Batch Delete Request
            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            do {
                try  context.execute(batchDeleteRequest)
            } catch {
                 print("error on delete")
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
}


