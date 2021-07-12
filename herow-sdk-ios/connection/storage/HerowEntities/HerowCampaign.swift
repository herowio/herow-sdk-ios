//
//  HerowCampaign.swift
//  herow-sdk-ios
//
//  Created by Damien on 26/01/2021.
//

import Foundation

@objc  class HerowCampaign: NSObject, Campaign {
    var id: String
    var name: String
    var begin: Double
    var end: Double?
    let cappings: [String: Int]?
    var daysRecurrence: [String]?
    var notification: Notification?
    var startHour: String?
    var stopHour: String?

   public func getId() -> String {
        return id
    }






    func getName() -> String {
        return name
    }



    func getBegin() -> Double {
        return begin
    }

    func getEnd() -> Double? {
        return end
    }







    func getCappings() -> [String : Int]? {
        return cappings
    }



    func getNotification() -> Notification? {
        return notification
    }

    func getDaysRecurrence() -> [String]? {
        return daysRecurrence
    }

    func getStartHour() -> String? {
        return startHour
    }

    func getStopHour() -> String? {
        return stopHour
    }


    init(campaign: Campaign) {
        self.id = campaign.getId()
        self.name = campaign.getName()
        self.begin = campaign.getBegin()
        self.end = campaign.getEnd()
        self.cappings = campaign.getCappings()
        self.daysRecurrence = campaign.getDaysRecurrence()
        self.notification = campaign.getNotification()
        self.stopHour = campaign.getStopHour()
        self.startHour = campaign.getStartHour()

    }
    required init(id: String,
         name: String,
         begin: Double,
         end: Double?,
         cappings: [String: Int]?,
         daysRecurrence: [String],
         notification: Notification?,
         startHour: String?,
         stopHour: String?) {

        self.id = id
        self.name = name
        self.begin = begin
        self.end = end
        self.cappings = cappings
        self.daysRecurrence = daysRecurrence
        self.notification = notification
        self.stopHour = stopHour
        self.startHour = startHour

    }
}
