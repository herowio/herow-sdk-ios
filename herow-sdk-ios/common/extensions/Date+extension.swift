//
//  Date+extension.swift
//  herow_sdk_ios
//
//  Created by Damien on 26/04/2021.
//

import Foundation

extension String {
    func toRecurencyDay(slot:RecurencySlot? = nil) -> RecurencyDay {
        var slotValue = slot
        var slotString = slot?.rawValue ?? ""
        var day: String? = nil
    let components = self.components(separatedBy: " ")
        if components.count == 2 {
            day =  components[0]
            slotString = components[1]
            slotValue = RecurencySlot(rawValue: slotString)
        }

        guard let slotValue = slotValue else {
            return .unknown
        }

        switch day {
        case "monday": return .monday(slot:slotValue)
        case "tuesday": return .tuesday(slot:slotValue)
        case "wednesday": return .wednesday(slot:slotValue)
        case "thursday": return .thursday(slot:slotValue)
        case "friday": return .friday(slot:slotValue)
        case "saturday": return .saturday(slot:slotValue)
        case "sunday": return .sunday(slot:slotValue)
        default:
            return .unknown
        }
    }
}

public  enum RecurencyDay: Codable, Hashable {
    case monday(slot: RecurencySlot)
    case tuesday(slot: RecurencySlot)
    case wednesday(slot: RecurencySlot)
    case thursday(slot: RecurencySlot)
    case friday(slot: RecurencySlot)
    case saturday(slot: RecurencySlot)
    case sunday(slot: RecurencySlot)
    case unknown

    func rawValue() -> String {
        switch self {
        case .monday(let slot):
            return "monday \(slot.rawValue)"
        case .tuesday(let slot):
            return "tuesday \(slot.rawValue)"
        case .wednesday(let slot):
            return "wednesday \(slot.rawValue)"
        case .thursday(let slot):
            return "thursday \(slot.rawValue)"
        case .friday(let slot):
            return "friday \(slot.rawValue)"
        case .saturday(let slot):
            return "saturday \(slot.rawValue)"
        case .sunday(let slot):
            return "sunday \(slot.rawValue)"
        default: return "RecurencyDay error"
        }
    }


}


public  enum RecurencySlot: String, Codable {
    case earlyMorning
    case lateMorning
    case lunchTime
    case earlyAfterNoon
    case lateAfterNoon
    case evening
    case night
    case unknown
}


extension Date {

 public static var  dateFormatter = DateFormatter()
 public static var  monthdateFormatter = DateFormatter()
 public static var  daySlotdateFormatter = DateFormatter()
 public static var  daydateFormatter: DateFormatter  = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.calendar = .current
        dateFormatter.dateFormat = "EEEE"
        return dateFormatter
    }()
    var startOfDay: Date
        {
            return Calendar.current.startOfDay(for: self)
        }

        func getDate(dayDifference: Int) -> Date {
            var components = DateComponents()
            components.day = dayDifference
            return Calendar.current.date(byAdding: components, to:startOfDay)!
        }

    func tomorrow() -> Date {
        return  self.startOfDay.addingTimeInterval(86400).startOfDay
    }
    // Convert local time to UTC (or GMT)
    func toGlobalTime() -> Date {
        let timezone = TimeZone.current
        let seconds = -TimeInterval(timezone.secondsFromGMT(for: self))
        return Date(timeInterval: seconds, since: self)
    }

    // Convert UTC (or GMT) to local time
    func toLocalTime() -> Date {
        let timezone = TimeZone.current
        let seconds = TimeInterval(timezone.secondsFromGMT(for: self))
        return Date(timeInterval: seconds, since: self)
    }


        public func setTime(hour: Int, min: Int) -> Date? {
            let x: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute, .second]
            let cal = Calendar.current
            var components = cal.dateComponents(x, from: self)

            components.timeZone = .current
            components.hour = hour
            components.minute = min
            components.second = 0

            return cal.date(from: components)
        }

    public func next(_ weekday: Weekday,
                     direction: Calendar.SearchDirection = .forward,
                     considerToday: Bool = false) -> Date
    {
        let calendar = Calendar(identifier: .gregorian)
        let components = DateComponents(weekday: weekday.rawValue)

        if considerToday &&
            calendar.component(.weekday, from: self) == weekday.rawValue
        {
            return self
        }

        return calendar.nextDate(after: self,
                                 matching: components,
                                 matchingPolicy: .nextTime,
                                 direction: direction)!
    }

    public enum Weekday: Int {
        case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday
    }


    public func  isHomeCompliant() -> Bool {
        Date.dateFormatter.dateFormat = "EEEE"
        Date.dateFormatter.locale =  NSLocale(localeIdentifier: "en_EN") as Locale
        guard let evening20 = self.setTime(hour: 20, min: 0), let evening2359 = self.setTime(hour: 23, min: 59), let morning00 = self.setTime(hour: 0, min: 0), let morning06 = self.setTime(hour: 6, min: 0) else {
            return false
        }
        let evening =  evening20 < self && evening2359 > self
        let morning =  morning00 < self && morning06 > self
        return (evening || morning)
    }


    public func  isSchoolCompliant() -> Bool {
        Date.dateFormatter.dateFormat = "EEEE"
        Date.dateFormatter.locale =  NSLocale(localeIdentifier: "en_EN") as Locale
        guard let moring0830 = self.setTime(hour:8, min: 40), let morning0900 = self.setTime(hour: 8, min: 50), let morning1130 = self.setTime(hour:11, min: 30), let morning12 = self.setTime(hour: 12, min: 00) , let after1330 = self.setTime(hour: 13, min: 20) , let after14 = self.setTime(hour: 13, min: 50), let after1630 = self.setTime(hour: 16, min: 30), let after17 = self.setTime(hour:17, min: 00) else {
            return false
        }
        let morningEntry =  moring0830 < self && morning0900 > self
        let morningExit =  morning1130 < self && morning12 > self
        let afterEntry =  after1330 < self && after14 > self
        let afterExit =  after1630 < self && after17 > self

        let isOff = ["Saturday","Sunday","Wednesday"].contains( Date.dateFormatter.string(from: self)) || ["July","August"].contains(self.month)
        return (morningEntry || morningExit || afterEntry || afterExit) && !isOff
    }

    public func  isWorkCompliant() -> Bool {
        Date.dateFormatter.dateFormat = "EEEE"
        Date.dateFormatter.locale =  NSLocale(localeIdentifier: "en_EN") as Locale
        guard let work09 = self.setTime(hour: 09, min: 0), let work12 = self.setTime(hour: 12, min: 00), let work14 = self.setTime(hour: 14, min: 0), let work18 = self.setTime(hour: 18, min: 0) else {
            return false
        }
        let morning =  work09 < self && work12 > self
        let afternoon =  work14 < self && work18 > self

        let isWeekEnd = ["Saturday","Sunday"].contains( Date.dateFormatter.string(from: self))
        return (afternoon || morning) && !isWeekEnd &&  !isSchoolCompliant()
    }

    public func  isOtherCompliant() -> Bool {
        //TODO not sure
      return !isHomeCompliant() && !isWorkCompliant() && !isSchoolCompliant() 
    }
}

extension Date {
    var month: String {
        Date.monthdateFormatter.dateFormat = "MMMM"
        return Date.monthdateFormatter.string(from: self)
    }

    var recurencyDay: RecurencyDay {

        switch  Date.daydateFormatter.string(from: self).lowercased() {
        case "monday": return .monday(slot: self.slot)
        case "tuesday": return .tuesday(slot: self.slot)
        case "wednesday": return .wednesday(slot: self.slot)
        case "thursday": return .thursday(slot: self.slot)
        case "friday": return .friday(slot: self.slot)
        case "saturday": return .saturday(slot: self.slot)
        case "sunday": return .sunday(slot: self.slot)
        default:
            return .monday(slot: .unknown)
        }

    }

    var slot: RecurencySlot {
        Date.daySlotdateFormatter.dateFormat = "HH"

        var defIdentifer =   Date.daySlotdateFormatter.locale.identifier
        if !defIdentifer.hasSuffix("_POSIX") {
            defIdentifer = defIdentifer+"_POSIX"
            let locale = Locale(identifier: defIdentifer)
            Date.daySlotdateFormatter.locale = locale
        }
        if let currentHour = Int( Date.daySlotdateFormatter.string(from: self)) {
            if(currentHour < 06){
                return .night
            }
            else if(currentHour < 10){
                return .earlyMorning
            }
            else if( currentHour < 12){
                return .lateMorning
            }
            else if( currentHour < 14){
                return .lunchTime
            }
            else if(currentHour < 16){
                return .earlyAfterNoon
            }
            else if(currentHour < 18){
                return .lateAfterNoon
            }
            else if(currentHour < 22){
                return .evening
            } else {
                return .night
            }
        }
        return .unknown
    }
}
