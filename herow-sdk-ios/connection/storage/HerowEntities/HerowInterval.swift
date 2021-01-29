//
//  HerowInterval.swift
//  herow-sdk-ios
//
//  Created by Damien on 26/01/2021.
//

import Foundation

struct HerowInterval: Interval {
    
    var start: Int64
    var end: Int64?

    func getStart() -> Int64 {
        return start
    }

    func getEnd() -> Int64? {
        return end
    }

    init(start: Int64, end: Int64) {
        self.start = start
        self.end = end
    }



}
