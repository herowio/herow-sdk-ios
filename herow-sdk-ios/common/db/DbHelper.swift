//
//  DbHelper.swift
//  ConnectPlaceCommon
//
//  Created by Ludovic Vimont on 16/09/2019.
//  Copyright © 2019 Connecthings. All rights reserved.
//

import Foundation

/// Use to escape some special characters while inserting string in the database
public class DbHelper {
    public static func addingSQLEscapes(_ string: String) -> String {
        let singleQuote = "'"
        let escapedQuote = "''"
        return singleQuote + string.replacingOccurrences(of: singleQuote, with: escapedQuote) + singleQuote
    }
}
