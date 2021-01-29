//
//  APICampaign.swift
//  herow-sdk-ios
//
//  Created by Damien on 25/01/2021.
//

import Foundation

public struct APICampaign: Campaign, Codable {
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
    var intervals: [APIInterval]?
    let cappings: [String: Int]?
    var triggers: [String: Int]
    var daysRecurrence: [String]?
    var tz: String
    var notification: APINotification?
    var recurrenceEnabled: Bool

    func getId() -> String {
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

    func getNotification() -> Notification? {
        return notification
    }

    func getDaysRecurrence() -> [String]? {
        return daysRecurrence
    }

    func getReccurenceEnable() -> Bool {
        return recurrenceEnabled
    }

    enum CodingKeys: String, CodingKey {
        case id
        case company
        case createdDate
        case modifiedDate
        case deleted
        case simpleId
        case name
        case begin //= "startHour"
        case end //= "stopHour"
        case intervals
        case notification
        case tz
        case realTimeContent
        case cappings = "capping"
        case triggers
        case daysRecurrence
        case recurrenceEnabled
    }
    init(id: String,
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
         recurrenceEnbaled:Bool,
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
        self.intervals = intervals as? [APIInterval]
        self.cappings = cappings
        self.triggers = triggers
        self.daysRecurrence = daysRecurrence
        self.recurrenceEnabled = recurrenceEnbaled
        self.tz = tz
        self.notification = notification as? APINotification

    }

    public  init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try values.decode(String.self, forKey: .id)
        self.company = try values.decode(String.self, forKey: .company)
        self.createdDate = try values.decode(Double.self, forKey: .createdDate)
        self.modifiedDate = try values.decode(Double.self, forKey: .modifiedDate)
        self.deleted = try values.decode(Bool.self, forKey: .deleted)
        self.simpleId = try values.decode(String.self, forKey: .simpleId)
        self.name = try values.decode(String.self, forKey: .name)
        self.begin = try values.decode(Double.self, forKey: .begin)
        self.end = try values.decodeIfPresent(Double.self, forKey: .end)
        self.intervals = try values.decode([APIInterval].self, forKey: .intervals)
        self.triggers = try values.decode([String: Int].self, forKey: .triggers)
        self.cappings = try values.decodeIfPresent([String: Int].self, forKey: .cappings) ?? [String: Int]()
        self.notification = try values.decodeIfPresent(APINotification.self, forKey: .notification)
        self.recurrenceEnabled = try values.decodeIfPresent(Bool.self, forKey: .recurrenceEnabled) ?? false
        self.daysRecurrence = try values.decodeIfPresent([String].self, forKey: .daysRecurrence)
        self.tz = try values.decode(String.self, forKey: .tz)
        self.realTimeContent = try values.decodeIfPresent(Bool.self, forKey: .realTimeContent) ?? false
    }

}
