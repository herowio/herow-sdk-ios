//
//  NotificationMananager.swift
//  herow_sdk_ios
//
//  Created by Damien on 19/04/2021.
//

import UIKit

protocol NotificationCenterProtocol {
    func add(_ request: UNNotificationRequest, withCompletionHandler completionHandler: ((Error?) -> Void)?)

}
class NotificationManager: NSObject, EventListener {

    internal var filters: [WeakContainer<NotificationFilter>] = [WeakContainer<NotificationFilter>]()
    private var cacheManager: CacheManagerProtocol
    private var notificationCenter: NotificationCenterProtocol
    
    init(cacheManager: CacheManagerProtocol, notificationCenter: NotificationCenterProtocol) {
        self.cacheManager = cacheManager
        self.notificationCenter = notificationCenter
    }

    public func addFilter( _ filter: NotificationFilter) {
        let first = filters.first {
            ($0.get() === filter) == true
        }
        if first == nil {
            filters.append(WeakContainer<NotificationFilter>(value: filter))
        }
    }

   public func removeFilter( _ filter: NotificationFilter) {
        filters = filters.filter {
            ($0.get() === filter) == false
        }
    }

    private func canCreateNotification( _ campaign : Campaign) -> Bool {
        for filter in filters {
          
            if let filter = filter.get() {
                if !(filter.createNotification(campaign: campaign)) {
                    return false
                }
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
                if (event == .GEOFENCE_ENTER && !campaign.isExit()) || (event == .GEOFENCE_EXIT && campaign.isExit() ) {
                    if canCreateNotification(campaign) {
                        createCampaignNotification(campaign)
                    }
                }
            }
        }
    }

    private func createCampaignNotification(_ campaign: Campaign) {

        guard let notification = campaign.getNotification() else {
            return
        }
        let content = UNMutableNotificationContent()

        content.title = notification.getTitle()
        content.body = notification.getDescription()
        let uuidString = UUID().uuidString
        let request = UNNotificationRequest(identifier: uuidString,
                                            content: content, trigger: nil)
        notificationCenter.add(request) { (error) in
            if error != nil {
                // Handle any errors.
            } else {
                GlobalLogger.shared.warning("create notification: \(campaign.getId())")
            }
        }
    }


    func didReceivedEvent(_ event: Event, infos: [ZoneInfo]) {
        for info in infos {
            createNotificationForEvent(event: event, info: info)
        }
    }
}
