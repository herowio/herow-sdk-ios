
//
//  Dispatcher.swift
//  EventDispatcher
//
//  Created by Damien on 16/11/2020.
//
import Foundation

enum Event: String {
    case GEOFENCE_ENTER
    case GEOFENCE_EXIT
    case GEOFENCE_VISIT
}

 protocol EventListener: class {
    func didReceivedEvent( _ event: Event, infos: [ZoneInfo])
}
  class EventDispatcher {
    static let shared = EventDispatcher()
    private var listeners : [Event : [WeakContainer<EventListener>]] =  [Event: [WeakContainer<EventListener>]]()

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
