//
//  DataBase.swift
//  herow-sdk-ios
//
//  Created by Damien on 25/01/2021.
//

import Foundation

protocol DataBase {
    func saveZonesInBase(items: [Zone], completion: (()->())?)
    func getZonesInBase(_ idList: [String]?) -> [Zone]
    func getZonesInBase() -> [Zone]
    func savePoisInBase(items: [Poi], completion: (()->())?)
    func getPoisInBase() -> [Poi]
    func saveCampaignsInBase(items: [Campaign], completion: (()->())?)
    func getCampaignsInBase() -> [Campaign]
    func purgeAllData(completion: (()->())?)
    func purgeCapping(completion: (()->())?)
    func getCapping(id: String) -> Capping?
    func saveCapping(_ capping: Capping, completion: (()->())?)
// QuadTree methods
    func getQuadTreeRoot() -> QuadTreeNode?
    func getNodeForId(_ id: String) ->  QuadTreeNode? 
    func saveQuadTree(_ node : QuadTreeNode,  completion: (()->())?)

}
