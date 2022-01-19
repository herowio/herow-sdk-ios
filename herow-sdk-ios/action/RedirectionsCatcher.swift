//
//  RedirectionsCatcher.swift
//  herow_sdk_ios
//
//  Created by Damien on 18/01/2022.
//

import Foundation


@objc public protocol RedirectionsListener: AnyObject {
    func didOpenNotification( campaignID: String, zoneID: String)
}

class RedirectionsCatcher: AnalyticsManagerListener {

    var listeners: [WeakContainer<RedirectionsListener>] = [WeakContainer<RedirectionsListener>]()


    deinit {
        for listener in listeners.compactMap({$0.get()}) {
            self.unRegisterRedirectionsListener(listener)
        }
    }
    func registerRedirectionsListener( _ listener: RedirectionsListener) {
        let first = listeners.first {
            ($0.get() === listener) == true
        }
        if first == nil {
            listeners.append(WeakContainer<RedirectionsListener>(value: listener))
        }
    }

    func unRegisterRedirectionsListener( _ listener: RedirectionsListener)  {
        listeners = listeners.filter {
            ($0.get() === listener) == false
        }
    }

    func didOpenNotificationForCampaign(_ campaign: Campaign, zoneID: String) {

        if let uri = campaign.getNotification()?.getUri() {
            if !uri.isEmpty {
                let url = URL(string:uri)
                _ = OpenUrlUtils.openUrl(url) { value in
                    print("open url:\(value)")
                }
            }
            else {
                for listener  in listeners.compactMap({$0.get()}) {
                    listener.didOpenNotification(campaignID: campaign.getId(), zoneID: zoneID)
                }
            }
        }
    }

    func didCreateNotificationForCampaign(_ campaign: Campaign, zoneID: String, zoneInfo: ZoneInfo) {
        //do nothing for now
    }

}
