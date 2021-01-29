
//
//  Dispatcher.swift
//  EventDispatcher
//
//  Created by Damien on 16/11/2020.
//
import Foundation

enum Event: String {
    case LOCATION_UPDATE
    case GEOFENCE_ENTER
    case GEOFENCE_EXIT
    case ZONE_VISIT
}

protocol EventListener: class {
    func didReceivedEvent( _ event: Event)
}

class EventDispatcher {
    static let shared = EventDispatcher()
    private var listeners : [Event : [WeakContainer<EventListener>]] =  [Event: [WeakContainer<EventListener>]]()
    func listen(_ observer: EventListener, event: Event) {
        if self.listeners[event] == nil {
            self.listeners[event] = [WeakContainer<EventListener>]()
        }
        self.listeners[event]?.append(WeakContainer(value: observer))
    }

    func post(event: Event) {
        guard let listenners = self.listeners[event] else {
            return
        }
        for listener in listenners {
            if let listener = listener.get() {
                listener.didReceivedEvent(event)
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
