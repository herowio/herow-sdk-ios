//
//  String+regex.swift
//  herow_sdk_ios
//
//  Created by Damien on 23/04/2021.
//

import Foundation

extension String {
    func dynamicValues(for regex: String) -> String  {
        let textMatches = matches(for: regex)
        var newtext = self
        textMatches.forEach { match in
            let str = match.replacingOccurrences(of: "{", with: "").replacingOccurrences(of: "}", with: "").replacingOccurrences(of: "default('", with: "").replacingOccurrences(of: "')", with: "")
            let components = str.components(separatedBy: "|")
            if components.count > 0 {
                newtext = newtext.replacingOccurrences(of: match, with: components[0] )
            }
            else if  components.count > 1 {
                newtext = newtext.replacingOccurrences(of: match, with: components[1] )
            }
        }
        return newtext
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
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
}
