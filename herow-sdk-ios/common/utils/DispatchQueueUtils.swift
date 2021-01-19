//
//  DispatchQueueUtils.swift
//  ConnectPlaceCommon
//
//  Created by Connecthings on 18/10/2017.
//  Copyright © 2017 Connecthings. All rights reserved.
//

import Foundation

public class DispatchQueueUtils {
    public static let userInitiated = DispatchQueue(label: "com.connecthings.queueu.userInitiated",
                                                    qos: .userInitiated)

    public static let userInteractive = DispatchQueue(label: "com.connecthings.queueu.userInteractive",
                                                      qos: .userInteractive)

    public static let databaseQueue = DispatchQueue(label: "com.connecthings.queueu.database",
                      qos: .utility,
                      attributes: DispatchQueue.Attributes.init(),
                      autoreleaseFrequency: .inherit, target: nil)
}
