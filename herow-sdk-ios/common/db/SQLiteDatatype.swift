//
//  SQLiteDatatype.swift
//  SQLiteDatabase
//
//  Created by Ludovic Vimont on 12/09/2019.
//  Copyright © 2019 Connecthings. All rights reserved.
//

import Foundation

/// Fundamental SQLite datatypes
/// #define SQLITE_INTEGER  1
/// #define SQLITE_FLOAT    2
/// # define SQLITE_TEXT     3
/// #define SQLITE_BLOB     4
/// #define SQLITE_NULL     5
/// @see: https://www.sqlite.org/capi3ref.html
public enum SQLiteDatatype: Int {
    case integer = 1
    case float   = 2
    case text    = 3
    case blob    = 4
    case null    = 5
}
