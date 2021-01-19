//
//  DataHolderUpdater.swift
//  ConnectPlaceCommon
//
//  Created by Amine GAHBICHE on 19/02/2018.
//  Copyright © 2018 Connecthings. All rights reserved.
//

import Foundation

public protocol DataHolderUpdater {
    /**
     * Permits to load the properties previously saved in the dataHolder
     * The load method is called only once when the application starts
     * @param dataHolder
     */
    func load(dataHolder: DataHolder)
    /**
     * Permits to save the properties that a class needs to perists
     * Be sure to use a unique key, the dataHolder is shared across several classes
     * The save method is called at the best time to ensure no property update will be lost.
     * @param dataHolder
     */
    func save(dataHolder: DataHolder)
}
