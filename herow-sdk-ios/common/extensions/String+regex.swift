//
//  String+regex.swift
//  herow_sdk_ios
//
//  Created by Damien on 23/04/2021.
//

import Foundation

struct DynamicValue {
    var newText: String
    var defaultValues: [String: String]
}

extension String {
    func dynamicValues(for regex: String) -> DynamicValue {
        let textMatches = matches(for: regex)
        var defaultValues = [String: String]()
        var newtext = self
        textMatches.forEach { match in
            let str = match.replacingOccurrences(of: "{", with: "").replacingOccurrences(of: "}", with: "").replacingOccurrences(of: "default('", with: "").replacingOccurrences(of: "')", with: "")
            let components = str.components(separatedBy: "|")
            if components.count > 1 {
                defaultValues[components[0]] = components[1]
                newtext = newtext.replacingOccurrences(of: match, with: components[0] )
            }
        }
        return DynamicValue(newText: newtext, defaultValues: defaultValues)
    }

    func matches(for regex: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: self,
                                        range: NSRange(self.startIndex..., in: self))
            return results.map {
                String(self[Range($0.range, in: self)!])
            }
        } catch let error {
            GlobalLogger.shared.error("regex :\(regex) invalid regex: \(error.localizedDescription)")
            return []
        }
    }
}
