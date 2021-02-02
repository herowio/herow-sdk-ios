//
//  AnalyticsManager.swift
//  herow-sdk-ios
//
//  Created by Damien on 01/02/2021.
//

import Foundation
import CoreLocation
class AnalyticsManager: EventListener, DetectionEngineListener, ClickAndConnectListener {

    private var  apiManager: APIManagerProtocol
    private var onClickAndCollect = false
    init(apiManager: APIManagerProtocol) {
        self.apiManager = apiManager
    }

    func didReceivedEvent(_ event: Event, infos: [ZoneInfo]) {
        for info in infos {
            let data = createlogEvent(event: event, info: info)
        }
    }

    func onLocationUpdate(_ location: CLLocation) {
      let data = createlogContex(location)

    }

    func createlogContex(_ location: CLLocation) -> Data {
        GlobalLogger.shared.debug("AnalyticsManager - createlogContex: \(location.coordinate.latitude) \(location.coordinate.longitude)")
        return Data()
    }

    func createlogEvent( event: Event,  info: ZoneInfo) -> Data {
        GlobalLogger.shared.debug("AnalyticsManager - createlogEvent event: \(event) zoneInfo: \(info.hash)")
        return Data()
    }

    func didStopClickAndConnect() {
        onClickAndCollect = false
    }

    func didStartClickAndConnect() {
        onClickAndCollect =  true
    }

}
