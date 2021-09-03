//
//  DataBase.swift
//  herow-sdk-ios
//
//  Created by Damien on 25/01/2021.
//

import Foundation
import CoreLocation
protocol DataBase {
    func saveZonesInBase(items: [Zone], completion: (()->())?)
    func getZonesInBase(_ idList: [String]?) -> [Zone]
    func getZonesInBase() -> [Zone]
    func savePoisInBase(items: [Poi], completion: (()->())?)
    func getPoisInBase() -> [Poi]
    func getNearbyPois(_ location: CLLocation, distance: CLLocationDistance, count: Int ) -> [Poi]
    func saveCampaignsInBase(items: [Campaign], completion: (()->())?)
    func getCampaignsInBase() -> [Campaign]
    func purgeAllData(completion: (()->())?)
    func purgeCapping(completion: (()->())?)
    func getCapping(id: String) -> Capping?
    func saveCapping(_ capping: Capping, completion: (()->())?)
// QuadTree methods
    func createQuadTreeRoot( completion: (()->())?)
    func reloadNewPois(completion: (()->())?)
    func getQuadTreeRoot() -> QuadTreeNode?
    func getNodeForId(_ id: String) ->  QuadTreeNode? 
    func saveQuadTree(_ node : QuadTreeNode,  completion: (()->())?)

    //analyse
    func getLocations(completion: @escaping ([QuadTreeLocation]) ->() )
    func getLocationsNumber() -> Int
    func reassignPeriodLocations(_ completion:  @escaping ()->())

    //historicMethod

    func getPeriods(dispatchLocation:Bool, completion: @escaping ([PeriodProtocol]) ->() )
    

}
