//
//  DataBase.swift
//  herow-sdk-ios
//
//  Created by Damien on 25/01/2021.
//

import Foundation

protocol DataBase {
    func saveZonesInBase(items: [Zone], completion: (()->())?)
    func getZonesInBase() -> [Zone]
    func savePoisInBase(items: [Poi], completion: (()->())?)
    func getPoisInBase() -> [Poi]
    func saveCampaignsInBase(items: [Campaign], completion: (()->())?)
    func getCampaignsInBase() -> [Campaign]
    func purgeAllData(completion: (()->())?)

}
