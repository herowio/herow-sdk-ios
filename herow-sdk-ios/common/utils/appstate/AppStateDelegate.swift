//
//  AppStateDetector.swift
//  ConnectPlaceCommon
//
//  Created by Olivier Stevens on 04/07/2017.
//  Copyright © 2017 Connecthings. All rights reserved.
//

import Foundation

import Foundation

@objc(CPAppStateDelegate) public protocol AppStateDelegate: class {
    /// Notify when the application enters in foreground
    @objc func onAppInForeground()
    /// Notify when the application enters in background
    @objc func onAppInBackground()
    /// Notify when the application willTerminate
    @objc optional func onAppTerminated()
}
