//
//  HerowCampaign.swift
//  herow-sdk-ios
//
//  Created by Damien on 26/01/2021.
//

import Foundation

@objc public class HerowCampaign: NSObject, Campaign {
    var id: String
    var company: String
    var createdDate: Double
    var modifiedDate: Double
    var deleted: Bool
    var simpleId: String
    var name: String
    var begin: Double
    var end: Double?
    var realTimeContent: Bool
    var intervals: [Interval]?
    let cappings: [String: Int]?
    var triggers: [String: Int]
    var daysRecurrence: [String]?
    var tz: String
    var notification: Notification?
    var recurrenceEnabled: Bool

   public func getId() -> String {
        return id
    }

    func getCompany() -> String {
        return company
    }

    func getCreatedDate() -> Double {
        return createdDate
    }

    func getModifiedDate() -> Double {
        return modifiedDate
    }

    func getDeleted() -> Bool {
        return deleted
    }

    func getName() -> String {
        return name
    }

    func getSimpleId() -> String {
        return simpleId
    }

    func getBegin() -> Double {
        return begin
    }

    func getEnd() -> Double? {
        return end
    }

    func getRealTimeContent() -> Bool {
        return realTimeContent
    }

    func getIntervals() -> [Interval]? {
        return intervals
    }

    func getTriggers() -> [String : Int] {
        return triggers
    }

    func getCappings() -> [String : Int]? {
        return cappings
    }

    func getTz() -> String {
        return tz
    }

   public func getNotification() -> Notification? {
        return notification
    }

    func getDaysRecurrence() -> [String]? {
        return daysRecurrence
    }

    func getReccurenceEnable() -> Bool {
        return recurrenceEnabled
    }

    init(campaign: Campaign) {
        self.id = campaign.getId()
        self.company = campaign.getCompany()
        self.name = campaign.getName()
        self.createdDate = campaign.getCreatedDate()
        self.modifiedDate = campaign.getModifiedDate()
        self.deleted = campaign.getDeleted()
        self.simpleId = campaign.getSimpleId()
        self.begin = campaign.getBegin()
        self.end = campaign.getEnd()
        self.realTimeContent = campaign.getRealTimeContent()
        self.intervals = campaign.getIntervals()
        self.cappings = campaign.getCappings()
        self.triggers = campaign.getTriggers()
        self.daysRecurrence = campaign.getDaysRecurrence()
        self.recurrenceEnabled = campaign.getReccurenceEnable()
        self.tz = campaign.getTz()
        self.notification = campaign.getNotification()

    }
    required init(id: String,
         company: String,
         name: String,
         createdDate: Double,
         modifiedDate: Double,
         deleted: Bool,
         simpleId: String,
         begin: Double,
         end: Double?,
         realTimeContent: Bool,
         intervals: [Interval]?,
         cappings: [String: Int]?,
         triggers:[String: Int],
         daysRecurrence: [String],
         recurrenceEnabled:Bool,
         tz:String,
         notification: Notification?) {

        self.id = id
        self.company = company
        self.name = name
        self.createdDate = createdDate
        self.modifiedDate = modifiedDate
        self.deleted = deleted
        self.simpleId = simpleId
        self.begin = begin
        self.end = end
        self.realTimeContent = realTimeContent
        self.intervals = intervals
        self.cappings = cappings
        self.triggers = triggers
        self.daysRecurrence = daysRecurrence
        self.recurrenceEnabled = recurrenceEnabled
        self.tz = tz
        self.notification = notification

    }
}
