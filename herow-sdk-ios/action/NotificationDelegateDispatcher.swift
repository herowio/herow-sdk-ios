//
//  NotificationDelegateDispatcher.swift
//  herow_sdk_ios
//
//  Created by Damien on 19/04/2021.
//

import Foundation
import UserNotifications


protocol NotificationCreationListener: AnyObject {
    func  didCreateNotificationForCampaign(_ campaign: Campaign, zoneID: String, zoneInfo: ZoneInfo)
}


@available(iOS 10.0, *)
public class NotificationDelegateDispatcher: NSObject, UNUserNotificationCenterDelegate {
    public static let instance = NotificationDelegateDispatcher()

    private var delegateWeakList = [WeakContainer<UNUserNotificationCenterDelegate>]()
    private var creationListeners = [WeakContainer<NotificationCreationListener>]()

    public override init() {
        super.init()
        if let firstDelegate = NotificationDelegateHolder.shared.delegate {
            registerDelegate(firstDelegate)
        }
            NotificationDelegateHolder.shared.delegate = self
    }

    public func registerDelegate(  _  delegate: UNUserNotificationCenterDelegate?) {
        if let delegate = delegate {
            let weakValue = WeakContainer(value: delegate)
            if !delegateWeakList.contains(weakValue) {
                 delegateWeakList.append(weakValue)
            }
        }
    }

     func registerCreationListener(listener: NotificationCreationListener) {
        let weakValue = WeakContainer(value: listener)
        if !creationListeners.contains(weakValue) {
            creationListeners.append(weakValue)
        }
    }

    func didCreateNotificationForCampaign(_ campaign: Campaign, zoneID: String, zoneInfo: ZoneInfo) {
        for listener in creationListeners {
            listener.get()?.didCreateNotificationForCampaign(campaign, zoneID: zoneID, zoneInfo: zoneInfo)
        }

    }

    public func foregroundNotificationEnabled() -> Bool {
        let selector = #selector(UNUserNotificationCenterDelegate.userNotificationCenter(_:willPresent:withCompletionHandler:))
        for delegate in delegates() {
            if delegate?.responds(to: selector) ?? false {
                return true
            }
        }
        return false
    }

    public func delegates() -> [UNUserNotificationCenterDelegate?] {
        return delegateWeakList.map { $0.get()}
    }

    public func userNotificationCenter(_ center: UNUserNotificationCenter,
                                       didReceive response: UNNotificationResponse,
                                       withCompletionHandler completionHandler: @escaping () -> Void) {
        for delegate in delegates() {
            delegate?.userNotificationCenter?(center, didReceive: response, withCompletionHandler: completionHandler)
        }
    }

    public func userNotificationCenter(_ center: UNUserNotificationCenter, openSettingsFor notification: UNNotification?) {
        if #available(iOS 12.0, *) {
            for delegate in delegates() {
                delegate?.userNotificationCenter?(center, openSettingsFor: notification)
            }
        }
    }

    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {

        for delegate in delegates() {
            delegate?.userNotificationCenter?(center, willPresent: notification, withCompletionHandler: completionHandler)
        }

        completionHandler([])

    }
}

@available(iOS 10.0, *)
class NotificationDelegateHolder {
    public static let shared: NotificationDelegateHolder = NotificationDelegateHolder()

    var useNotificationCenter = true

    public var delegate: UNUserNotificationCenterDelegate? {
        get {
            var delegate: UNUserNotificationCenterDelegate?
            if useNotificationCenter {
                delegate = UNUserNotificationCenter.current().delegate
            } else {
                delegate = MockNotificationCenter.shared.delegate
            }
            return delegate
        }
        set(newValue) {
            if useNotificationCenter {
                UNUserNotificationCenter.current().delegate = newValue
            } else {
                MockNotificationCenter.shared.delegate = newValue
            }
        }
    }
}

@available(iOS 10.0, *)
public class MockNotificationCenter: NotificationCenterProtocol {
    func getDeliveredNotifications(completionHandler: @escaping ([UNNotification]) -> Void) {
          print("getDeliveredNotifications.")
    }

    weak var delegate: UNUserNotificationCenterDelegate?
    public static let shared = MockNotificationCenter()
    public func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {
        GlobalLogger.shared.debug("Remove notification...")
    }

    @available(iOS 10.0, *)
    public func add(_ request: UNNotificationRequest, withCompletionHandler completionHandler: ((Error?) -> Void)?) {
        GlobalLogger.shared.debug("Add notification...")
        completionHandler?(nil)
      /*  let trigger  = request.trigger as? UNTimeIntervalNotificationTrigger
        if let trigger = trigger {
            let interval  = trigger.timeInterval
            /*let userInfo: [AnyHashable: Any] = request.content.userInfo
            DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
                self.notifyDisplayToNotificationManager(userInfo)
            }*/
        }*/
    }

    public func userNotificationCenter(_ center: UNUserNotificationCenter, openSettingsFor notification: UNNotification?) {
          GlobalLogger.shared.debug(" MOCK userNotificationCenter(_ center: UNUserNotificationCenter, openSettingsFor notification: UNNotification?)")
    }

    @available(iOS 10.0, *)
    public func  removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        GlobalLogger.shared.debug("remove pending notification...")

    }
    @available(iOS 10.0, *)
    public func registerDelegate(_ delegate: UNUserNotificationCenterDelegate?) {
         self.delegate = delegate

    }
   @available(iOS 10.0, *)
    public func getDelegate() -> UNUserNotificationCenterDelegate? {
        return self.delegate
    }

}

