//
//  CoreDataManager.swift
//  herow-sdk-ios
//
//  Created by Damien on 25/01/2021.
//

import Foundation
import CoreData

class CoreDataManager<Z: Zone, A: Access,P: Poi,C: Campaign, I: Interval, N: Notification, Q: Capping>: DataBase {

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
                campaignCoreData?.company = item.getCompany()
                campaignCoreData?.createdDate = item.getCreatedDate()
                campaignCoreData?.modifiedDate = item.getModifiedDate()
                campaignCoreData?.isDeleted = item.getDeleted()
                campaignCoreData?.simpleId = item.getSimpleId()
                campaignCoreData?.name = item.getName()
                campaignCoreData?.begin = item.getBegin()
                campaignCoreData?.end = item.getEnd() ?? 0
                campaignCoreData?.startHour = item.getStartHour() ?? ""
                campaignCoreData?.stopHour = item.getStopHour() ?? ""
                campaignCoreData?.realTimeContent = item.getRealTimeContent()
                var intervalsCoreData = [IntervalCoreData]()
                if let intervals = item.getIntervals() {
                    for interval in intervals {
                        let entity = NSEntityDescription.entity(forEntityName: StorageConstants.IntervalCoreDataEntityName,
                                                                in: bgContext)!
                        let intervalCoreData = IntervalCoreData(entity: entity,
                                                                insertInto: bgContext)
                        intervalCoreData.start = interval.getStart()
                        intervalCoreData.end = interval.getEnd() ?? 0
                        intervalsCoreData.append(intervalCoreData)
                    }
                    campaignCoreData?.intervals = Set(intervalsCoreData)
                }
                campaignCoreData?.cappings = item.getCappings() ?? [String: Int]()
                campaignCoreData?.triggers = item.getTriggers()
                campaignCoreData?.recurrenceEnabled = item.getReccurenceEnable()
                campaignCoreData?.daysRecurrence = item.getDaysRecurrence() ?? [String]()
                campaignCoreData?.tz = item.getTz()
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
                if accessInBase  == nil {
                    let entity =
                        NSEntityDescription.entity(forEntityName: StorageConstants.AccessCoreDataEntityName,
                                                   in: bgContext)!
                    accessInBase = AccessCoreData(entity: entity,
                                                  insertInto: bgContext)
                }
                if let access = item.getAccess() {
                    accessInBase?.id = access.getId()
                    accessInBase?.name = access.getName()
                    accessInBase?.address = access.getAddress()
                }
                if let accessInBase = accessInBase {
                    zoneCoreData?.access = accessInBase
                }
                zoneCoreData?.lat = item.getLat()
                zoneCoreData?.lng = item.getLng()
                zoneCoreData?.radius = item.getRadius()
                zoneCoreData?.liveEvent = item.getLiveEvent()
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
                let liveevent = zoneCoreData.liveEvent
                let zone: Z = Z(hash: hash, lat:lat, lng: lng, radius: radius, campaigns: campaigns, access: access, liveEvent: liveevent)
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
                let company = campaignsCoreData.company
                let createdDate = campaignsCoreData.createdDate
                let modifiedDate = campaignsCoreData.modifiedDate
                let deleted = campaignsCoreData.isDeleted
                let simpleId = campaignsCoreData.simpleId
                let begin = campaignsCoreData.begin
                let end = campaignsCoreData.end
                let realTimeContent = campaignsCoreData.realTimeContent
                let intervalsCoreData = campaignsCoreData.intervals
                var intervals = [I]()
                for intervalCoreData in intervalsCoreData {
                    let interval = I(start: intervalCoreData.start, end: intervalCoreData.end)
                    intervals.append(interval)
                }
                let cappings = campaignsCoreData.cappings
                let triggers = campaignsCoreData.triggers
                let daysRecurrence = campaignsCoreData.daysRecurrence
                let tz = campaignsCoreData.tz
                let startHour = campaignsCoreData.startHour
                let stopHour = campaignsCoreData.stopHour
                let recurrenceEnabled = campaignsCoreData.recurrenceEnabled
                let  notification = N(title: campaignsCoreData.notification.title, description: campaignsCoreData.notification.content,image: campaignsCoreData.notification.image, thumbnail: campaignsCoreData.notification.thumbnail,textToSpeech: campaignsCoreData.notification.textToSpeech, uri : campaignsCoreData.notification.uri)
                let campaign = C(id: id, company: company, name: name, createdDate: createdDate, modifiedDate: modifiedDate, deleted: deleted, simpleId: simpleId, begin: begin, end: end, realTimeContent: realTimeContent, intervals: intervals, cappings: cappings, triggers: triggers, daysRecurrence: daysRecurrence, recurrenceEnabled: recurrenceEnabled, tz: tz, notification: notification, startHour: startHour, stopHour: stopHour)
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

                cappingCoreData?.campaignId = capping.getId()
                cappingCoreData?.razDate = capping.getRazDate()
                cappingCoreData?.count = capping.getCount()
            }
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
        let uniqueNames = persistentContainer.managedObjectModel.entities.compactMap({ $0.name }).filter({$0 != StorageConstants.CappingCoreDataEntityName})
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

}

