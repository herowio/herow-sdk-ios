//
//  NotificationMananager.swift
//  herow_sdk_ios
//
//  Created by Damien on 19/04/2021.
//

import UIKit

enum DynamicKeys : String, CaseIterable {
    case radius = "zone.radius"
    case name = "zone.name"
    case address = "zone.address"
    case customId = "user.customId"
}
protocol NotificationCenterProtocol {
    func add(_ request: UNNotificationRequest, withCompletionHandler completionHandler: ((Error?) -> Void)?)

    func removeDeliveredNotifications(withIdentifiers identifiers: [String])

    func removePendingNotificationRequests(withIdentifiers identifiers: [String])

    func getDeliveredNotifications(completionHandler: @escaping ([UNNotification]) -> Void)

}
class NotificationManager: NSObject, EventListener {

    internal var filters: [NotificationFilter] = [NotificationFilter]()
    private var onExactZoneEntry: Bool = false
    private var cacheManager: CacheManagerProtocol
    private var notificationCenter: NotificationCenterProtocol
    private var herowDataStorage: HerowDataStorageProtocol
    init(cacheManager: CacheManagerProtocol, notificationCenter: NotificationCenterProtocol, herowDataStorage: HerowDataStorageProtocol) {
        self.cacheManager = cacheManager
        self.notificationCenter = notificationCenter
        self.herowDataStorage = herowDataStorage
        super.init()
        self.addFilter(ValidityFilter())
        self.addFilter(RecurencyFilter())
        self.addFilter(TimeSlotFilter())
        self.addFilter(CappingFilter(timeProvider: TimeProviderAbsolute(), cacheManager: self.cacheManager))
    }

    public func addFilter( _ filter: NotificationFilter) {
        let first = filters.first {
            ($0 === filter) == true
        }
        if first == nil {
            filters.append(filter)
        }
    }

   public func removeFilter( _ filter: NotificationFilter) {
        filters = filters.filter {
            ($0 === filter) == false
        }
    }

    private func canCreateNotification( _ campaign : Campaign) -> Bool {
        for filter in filters {
                if !(filter.createNotification(campaign: campaign, completion: nil)) {
                    return false
                }
        }
        GlobalLogger.shared.warning("can reate notification")
        return true
    }

    private func createNotificationForEvent( event: Event,  info: ZoneInfo) {
        guard let zone = info.getZone() else {return}//cacheManager.getZones(ids: [info.zoneHash])
        //for zone in zones {
            let campaigns = cacheManager.getCampaignsForZone(zone)
            for campaign in campaigns {
                if (trigger(event: event, campaign: campaign) ) {
                    if canCreateNotification(campaign) {
                        DispatchQueueUtils.delay(bySeconds: 0.1, dispatchLevel: .main) {
                            self.createCampaignNotification(campaign, zone: zone, zoneInfo: info )
                        }
                    }
                }
            }
       // }
    }

    private func trigger(event: Event, campaign: Campaign) -> Bool {
      //  return (event == .GEOFENCE_ENTER && !campaign.isExit()) || (event == .GEOFENCE_EXIT && campaign.isExit())
      //  return event == .GEOFENCE_NOTIFICATION_ZONE_ENTER && !campaign.isExit()

        return  onExactZoneEntry ? event == .GEOFENCE_ENTER : event == .GEOFENCE_NOTIFICATION_ZONE_ENTER
    }
    private func createCampaignNotification(_ campaign: Campaign, zone: Zone, zoneInfo: ZoneInfo) {

        guard let notification = campaign.getNotification() else {
            return
        }
        let content = UNMutableNotificationContent()
        let title = computeDynamicContent(notification.getTitle(), zone: zone, campaign: campaign)
        let description = computeDynamicContent(notification.getDescription(), zone: zone, campaign: campaign)
        content.title = title
        content.body = description
        content.userInfo = ["zoneID": zone.getHash()]
        GlobalLogger.shared.debug("create notification title: \(title)")
        GlobalLogger.shared.debug("create notificationd description: \(description)")
        let uuidString = campaign.getId() + "_\(zone.getHash())"
        let request = UNNotificationRequest(identifier: uuidString,
                                            content: content, trigger: nil)
        notificationCenter.add(request) { (error) in
            if error != nil {
                // Handle any errors.
            } else {
                GlobalLogger.shared.warning("create notification: \(campaign.getId())")
                NotificationDelegateDispatcher.instance.didCreateNotificationForCampaign(campaign, zoneID: zone.getHash(), zoneInfo: zoneInfo)
            }
        }
    }

    func didReceivedEvent(_ event: Event, infos: [ZoneInfo]) {
        for info in infos {
            createNotificationForEvent(event: event, info: info)
        }
    }

    internal func computeDynamicContent(_ text:  String, zone: Zone, campaign: Campaign) -> String {
        return HerowInitializer.instance.computeDynamicContent(text, zone: zone, campaign: campaign)
    }

    func notificationsOnExactZoneEntry(_ value: Bool) {
        onExactZoneEntry = value
    }

    func isNotificationsOnExactZoneEntry() -> Bool {
        return onExactZoneEntry
    }
}
