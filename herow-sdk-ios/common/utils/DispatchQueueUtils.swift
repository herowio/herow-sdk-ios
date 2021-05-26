//
//  DispatchQueueUtils.swift
//  ConnectPlaceCommon
//
//  Created by Connecthings on 18/10/2017.
//  Copyright © 2017 Connecthings. All rights reserved.
//

import Foundation
public enum DispatchLevel {
    case main, userInteractive, userInitiated, utility, background
   public var dispatchQueue: DispatchQueue {
        switch self {
        case .main:                 return DispatchQueue.main
        case .userInteractive:      return DispatchQueue.global(qos: .userInteractive)
        case .userInitiated:        return DispatchQueue.global(qos: .userInitiated)
        case .utility:              return DispatchQueue.global(qos: .utility)
        case .background:           return DispatchQueue.global(qos: .background)
        }
    }
}
public class DispatchQueueUtils {
    public static let userInitiated = DispatchQueue(label: "com.connecthings.queueu.userInitiated",
                                                    qos: .userInitiated)

    public static let userInteractive = DispatchQueue(label: "com.connecthings.queueu.userInteractive",
                                                      qos: .userInteractive)

    public static let databaseQueue = DispatchQueue(label: "com.connecthings.queueu.database",
                      qos: .utility,
                      attributes: DispatchQueue.Attributes.init(),
                      autoreleaseFrequency: .inherit, target: nil)

    public static func delay(bySeconds seconds: Double, dispatchLevel: DispatchLevel = .main, closure: @escaping () -> Void) {
        let dispatchTime = DispatchTime.now() + seconds
        dispatchLevel.dispatchQueue.asyncAfter(deadline: dispatchTime, execute: closure)
    }



}
