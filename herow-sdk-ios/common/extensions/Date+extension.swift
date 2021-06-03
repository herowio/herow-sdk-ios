//
//  Date+extension.swift
//  herow_sdk_ios
//
//  Created by Damien on 26/04/2021.
//

import Foundation

extension Date {

 public static var  dateFormatter = DateFormatter()
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
        let evening =  evening20 < self.toLocalTime() && evening2359 > self.toLocalTime()
        let morning =  morning00 < self.toLocalTime() && morning06 > self.toLocalTime()

      //  let isWeekEnd = ["Satursday","Sunday"].contains( Date.dateFormatter.string(from: self))
        return (evening || morning)
    }


    public func  isSchoolCompliant() -> Bool {
        Date.dateFormatter.dateFormat = "EEEE"
        Date.dateFormatter.locale =  NSLocale(localeIdentifier: "en_EN") as Locale
        guard let moring0830 = self.setTime(hour:8, min: 30), let morning0900 = self.setTime(hour: 8, min: 45), let morning1130 = self.setTime(hour:11, min: 40), let morning12 = self.setTime(hour: 11, min: 50) , let after1330 = self.setTime(hour: 13, min: 30) , let after14 = self.setTime(hour: 13, min: 45), let after1630 = self.setTime(hour: 16, min: 30), let after17 = self.setTime(hour:16, min: 50) else {
            return false
        }
        let morningEntry =  moring0830 < self.toLocalTime() && morning0900 > self.toLocalTime()
        let morningExit =  morning1130 < self.toLocalTime() && morning12 > self.toLocalTime()
        let afterEntry =  after1330 < self.toLocalTime() && after14 > self.toLocalTime()
        let afterExit =  after1630 < self.toLocalTime() && after17 > self.toLocalTime()

        let isOff = ["Satursday","Sunday","Wednesday"].contains( Date.dateFormatter.string(from: self))
        return (morningEntry || morningExit || afterEntry || afterExit) && !isOff
    }

    public func  isWorkCompliant() -> Bool {
        Date.dateFormatter.dateFormat = "EEEE"
        Date.dateFormatter.locale =  NSLocale(localeIdentifier: "en_EN") as Locale
        guard let work09 = self.setTime(hour: 09, min: 0), let work12 = self.setTime(hour: 12, min: 00), let work14 = self.setTime(hour: 14, min: 0), let work18 = self.setTime(hour: 18, min: 0) else {
            return false
        }
        let morning =  work09 < self.toLocalTime() && work12 > self.toLocalTime()
        let afternoon =  work14 < self.toLocalTime() && work18 > self.toLocalTime()

        let isWeekEnd = ["Saturday","Sunday"].contains( Date.dateFormatter.string(from: self))
        return (afternoon || morning) && !isWeekEnd
    }

    public func  isOtherCompliant() -> Bool {
        //TODO not sure
      return !isHomeCompliant() && !isWorkCompliant() && !isSchoolCompliant() 
    }


}
