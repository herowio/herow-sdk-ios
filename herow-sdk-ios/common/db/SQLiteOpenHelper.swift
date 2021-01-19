//
//  SQLiteOpenHelper.swift
//  SQLiteDatabase
//
//  Created by Ludovic Vimont on 11/09/2019.
//  Copyright © 2019 Connecthings. All rights reserved.
//

import Foundation

/// An helper to facilitate a table creation of your database, just extend your class with this one
/// And don't **forget** to override the onCreate method !!
open class SQLiteOpenHelper: NSObject {
    private var dbName: String = ""
    private var db: SQLiteDatabase? = nil

    public init(dbName: String, debug: Bool = false) {
        super.init()
        self.dbName = dbName
        self.db = try? SQLiteDatabase(dbName, debug: debug)
        if let db = db {
            self.onCreate(db: db)
        }
    }

    // Return the name of the SQLite database being opened, as given to the constructor.
    public func getDatabaseName() -> String {
        return dbName
    }

    // Create and/or open a database that will be used for reading and writing.
    public func getDatabase() -> SQLiteDatabase? {
        return db
    }

    // Called when the database is created for the first time.
    open func onCreate(db: SQLiteDatabase) {
        preconditionFailure("You must override this method...")
    }
}
