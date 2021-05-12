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
        let zones = cacheManager.getZones(ids: [info.zoneHash])
        for zone in zones {
            let campaigns = cacheManager.getCampaignsForZone(zone)
            for campaign in campaigns {
                if (trigger(event: event, campaign: campaign) ) {
                    if canCreateNotification(campaign) {
                        createCampaignNotification(campaign, zone: zone, zoneInfo: info )
                    }
                }
            }
        }
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
        let dynamicValues =  text.dynamicValues(for: "\\{\\{(.*?)\\}\\}")
        var result = dynamicValues.newText
        let defaultValues = dynamicValues.defaultValues
        GlobalLogger.shared.debug("create dynamic content notification: \(campaign.getId())")
        DynamicKeys.allCases.forEach() { key in
            var value = ""
            switch key {
            case .name:
                value = zone.getAccess()?.getName() ?? (defaultValues[key.rawValue] ?? "")
            case .radius:
                value = "\(zone.getRadius())"
            case .address:
                value = zone.getAccess()?.getAddress() ??  (defaultValues[key.rawValue] ?? "")
            case .customId:
                value = herowDataStorage.getCustomId() ??  (defaultValues[key.rawValue] ?? "")
            }
            GlobalLogger.shared.debug("dynamic content replacing by key : \(DynamicKeys.name.rawValue) with \( String(describing: zone.getAccess()?.getName()))")
            GlobalLogger.shared.debug("dynamic content replacing by key : \(DynamicKeys.radius.rawValue) with \(zone.getRadius())")
            GlobalLogger.shared.debug("dynamic content replacing by key : \(DynamicKeys.address.rawValue) with \(String(describing: zone.getAccess()?.getAddress()))")
            GlobalLogger.shared.debug("dynamic content replacing by key : \(DynamicKeys.customId.rawValue) with \( String(describing: herowDataStorage.getCustomId()))")
            GlobalLogger.shared.debug("dynamic content replacing: \(key.rawValue) with \(value)")
            result = result.replacingOccurrences(of: key.rawValue, with: value)
        }
        GlobalLogger.shared.debug("create dynamic content notification: \(text)")
        GlobalLogger.shared.debug("create dynamic content notification tupple: \(dynamicValues)")
        GlobalLogger.shared.debug("create dynamic content notification result: \(result)")
        return result
    }

    func notificationsOnExactZoneEntry(_ value: Bool) {
        onExactZoneEntry = value
    }
}
