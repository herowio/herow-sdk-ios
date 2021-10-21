
//
//  Dispatcher.swift
//  EventDispatcher
//
//  Created by Damien on 16/11/2020.
//
import Foundation

@objc public enum Event: Int, Codable {
    case GEOFENCE_ENTER
    case GEOFENCE_EXIT
    
    case GEOFENCE_NOTIFICATION_ZONE_ENTER
    case GEOFENCE_NOTIFICATION_ZONE_EXIT
    case GEOFENCE_VISIT

    case LIVE_HOME
    case LIVE_WORK
    case LIVE_SCHOOL
    case LIVE_SHOP


    public func toString() -> String {
        switch self {
        case .GEOFENCE_EXIT:
            return "GEOFENCE_EXIT"
        case .GEOFENCE_NOTIFICATION_ZONE_ENTER:
            return "GEOFENCE_NOTIFICATION_ZONE_ENTER"
        case .GEOFENCE_NOTIFICATION_ZONE_EXIT:
            return "GEOFENCE_NOTIFICATION_ZONE_EXIT"
        case .GEOFENCE_ENTER:
            return "GEOFENCE_ENTER"
        case .GEOFENCE_VISIT:
            return "GEOFENCE_VISIT"
        case .LIVE_HOME:
            return "LIVE_HOME"
        case .LIVE_WORK:
            return "LIVE_WORK"
        case .LIVE_SCHOOL:
            return "LIVE_SCHOOL"
        case .LIVE_SHOP:
            return "LIVE_SHOP"
        }
    }
}

@objc public protocol   EventListener: AnyObject {
    func didReceivedEvent( _ event: Event, infos: [ZoneInfo])
}
  class EventDispatcher {
 
    internal var listeners : [Event : [WeakContainer<EventListener>]] =  [Event: [WeakContainer<EventListener>]]()

    func registerListener(_ observer: EventListener, event: Event) {
        if self.listeners[event] == nil {
            self.listeners[event] = [WeakContainer<EventListener>]()
        }
        self.listeners[event]?.append(WeakContainer(value: observer))
    }

    func registerListener(_ observer: EventListener) {
        registerListener(observer, event: .GEOFENCE_ENTER)
        registerListener(observer, event: .GEOFENCE_EXIT)
        registerListener(observer, event: .GEOFENCE_VISIT)
        registerListener(observer, event: .GEOFENCE_NOTIFICATION_ZONE_ENTER)
        registerListener(observer, event: .GEOFENCE_NOTIFICATION_ZONE_EXIT)
        registerListener(observer, event: .LIVE_HOME)
        registerListener(observer, event: .LIVE_WORK)
        registerListener(observer, event: .LIVE_SCHOOL)
        registerListener(observer, event: .LIVE_SHOP)
    }

    func post(event: Event, infos: [ZoneInfo]) {
        guard let listenners = self.listeners[event] else {
            return
        }
        for listener in listenners {
            if let listener = listener.get() {
                listener.didReceivedEvent(event, infos: infos)
            }
        }
    }

    func stopListening(forEvent: Event, listener: EventListener) {
        guard let listenners = self.listeners[forEvent] else {
            return
        }
        let newlistenners = listenners.filter {
            ($0.get() === listener) == false
        }
        self.listeners[forEvent] = newlistenners
    }
}
