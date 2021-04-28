//
//  Date+extension.swift
//  herow_sdk_ios
//
//  Created by Damien on 26/04/2021.
//

import Foundation

extension Date {


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

            return cal.date(from: components)?.toLocalTime()
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


}
