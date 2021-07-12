//
//  APICampaign.swift
//  herow-sdk-ios
//
//  Created by Damien on 25/01/2021.
//

import Foundation

struct APICampaign: Campaign, Codable {
    var id: String
    var name: String
    var image: String?
    var thumbnail:String?
    var begin: Double
    var end: Double?
    let cappings: [String: Int]?
    var daysRecurrence: [String]?
    var startHour: String?
    var stopHour: String?
    var notification: APINotification?

    func getId() -> String {
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

    enum CodingKeys: String, CodingKey {
        case id

        case name
        case begin
        case end
        case notification
        case cappings = "capping"
        case daysRecurrence
        case startHour
        case stopHour
    }
    init(id: String,
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
        self.notification = notification as? APINotification
        self.stopHour = stopHour
        self.startHour = startHour

    }

    public  init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try values.decode(String.self, forKey: .id)
        self.name = try values.decode(String.self, forKey: .name)
        self.begin = try values.decode(Double.self, forKey: .begin)
        self.end = try values.decodeIfPresent(Double.self, forKey: .end)
        self.cappings = try values.decodeIfPresent([String: Int].self, forKey: .cappings) ?? [String: Int]()
        self.notification = try values.decodeIfPresent(APINotification.self, forKey: .notification)
        self.daysRecurrence = try values.decodeIfPresent([String].self, forKey: .daysRecurrence)
        self.startHour =  try values.decodeIfPresent(String.self, forKey: .startHour)
        self.stopHour =  try values.decodeIfPresent(String.self, forKey: .stopHour)
    }

}
