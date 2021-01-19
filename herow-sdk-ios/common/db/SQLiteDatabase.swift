//
//  SQLiteDatabase.swift
//  SQLiteDatabase
//
//  Created by Ludovic Vimont on 11/09/2019.
//  Copyright © 2019 Connecthings. All rights reserved.
//

import Foundation
import SQLite3

typealias SQLiteDBPointer = OpaquePointer

/// Exposes methods to manage a SQLite database, you will find method to :
/// - Create
/// - Insert
/// - Update
/// - Delete
/// - Drop
/// You also can make a transaction.
public class SQLiteDatabase {
    private let SQLiteErrorDomain = "SQLiteError"
    fileprivate let sqliteDbPointer: SQLiteDBPointer
    private var version: Int = 1
    private var path: String = "connecthings.db"
    private var debug: Bool = false

    // SQLite supports three different threading modes:
    // - Single-thread. In this mode, all mutexes are disabled and SQLite is unsafe to use in more than a single thread at once.
    // - Multi-thread. In this mode, SQLite can be safely used by multiple threads provided that no single database connection is used simultaneously in two or more threads.
    // - Serialized. In serialized mode, SQLite can be safely used by multiple threads with no restriction.
    // @see: https://stackoverflow.com/questions/49198831/sqlite3-dylib-illegal-multi-threaded-access-to-database-connection
    convenience init(_ path: String) throws {
        try self.init(path, debug: false)
    }

    init(_ path: String, debug: Bool) throws {
        self.debug = debug
        self.path = path
        var sqliteDbPointer: SQLiteDBPointer?
        let dbFile: String = try FileUtils.generateDocumentPath(directory: .applicationSupportDirectory,
                                                                fileName: path).absoluteString
        if debug {
            GlobalLogger.shared.debug(dbFile)
        }
        FileUtils.createAppSupportDirectoryIfNeeded()
        let openResult = sqlite3_open_v2(dbFile, &sqliteDbPointer, SQLITE_OPEN_CREATE|SQLITE_OPEN_READWRITE|SQLITE_OPEN_FULLMUTEX, nil)
        if openResult != SQLITE_OK {
            let resultCode = sqlite3_errcode(sqliteDbPointer)
            let errorMsg = sqlite3_errmsg(sqliteDbPointer)
            let result = "resultCode: \(resultCode) - errorMsg: \(String(describing: errorMsg))"
            GlobalLogger.shared.debug(result)
            throw NSError(domain: SQLiteErrorDomain, code: Int(resultCode), userInfo: [NSLocalizedDescriptionKey: result])
        }
        self.sqliteDbPointer = sqliteDbPointer!
        // enable foregin keys
        let foreginKeyResult = sqlite3_exec(sqliteDbPointer, "PRAGMA foreign_keys = on", nil, nil, nil)
        if foreginKeyResult != SQLITE_OK {
            let resultCode = sqlite3_errcode(sqliteDbPointer)
            let errorMsg = sqlite3_errmsg(sqliteDbPointer)
            let result = "resultCode: \(resultCode) - errorMsg: \(String(describing: errorMsg))"
            GlobalLogger.shared.debug(result)
        }
    }

    deinit {
        close()
    }

    // Gets the path to the database file.
    public func getPath() -> String {
        return path
    }

    // Gets the database version.
    public func getVersion() -> Int {
        return version
    }

    // Execute a single SQL statement that is NOT a SELECT or any other SQL statement that returns data.
    public func execSQL(_ sql: String) -> Bool {
        var result: Bool = false
        var statement: OpaquePointer?
        if debug {
            GlobalLogger.shared.debug("execSQL: \(sql))")
        }
        let prepareResult = sqlite3_prepare_v2(sqliteDbPointer, sql, -1, &statement, nil)
        if prepareResult == SQLITE_OK {
            let stepResult = sqlite3_step(statement)
            if stepResult == SQLITE_DONE {
                result = true
            } else {
                let errorMessage = String.init(cString: sqlite3_errmsg(sqliteDbPointer))
                GlobalLogger.shared.debug("impossible to create database - step operation returned the following code: \(stepResult)\nMessage: \(errorMessage)")
            }
            sqlite3_finalize(statement)
        } else {
            let errorMessage = String.init(cString: sqlite3_errmsg(sqliteDbPointer))
            GlobalLogger.shared.debug("Prepare operation returned the following code: \(prepareResult)\nMessage: \(errorMessage)")
        }
        return result
    }

    // CRUD
    public func query(table: String) -> Cursor? {
        return self.query(table: table, columns: nil)
    }

    public func query(table: String, columns: [String]?) -> Cursor? {
        return self.query(table: table, columns: columns, whereClause: nil)
    }

    public func query(table: String, columns: [String]?, whereClause: String?) -> Cursor? {
        return self.query(table: table, columns: columns, whereClause: whereClause, orderBy: nil, limit: nil)
    }

    public func query(table: String, columns: [String]?, whereClause: String?, orderBy: String?) -> Cursor? {
        return self.query(table: table, columns: columns, whereClause: whereClause, orderBy: orderBy, limit: nil)
    }

    public func query(table: String, columns: [String]?, whereClause: String?, orderBy: String?, limit: String?) -> Cursor? {
        var columnsString = ""
        if let columns = columns {
            for column in columns {
                columnsString += "\(column), "
            }
            columnsString = String(columnsString.dropLast(2))
        } else {
            columnsString += "*"
        }
        var queryString = "SELECT \(columnsString) FROM \(table)"
        if let whereClause = whereClause {
            queryString += " WHERE \(whereClause)"
        }
        if let orderBy = orderBy {
            queryString += " ORDER BY \(orderBy)"
        }
        if let limit = limit {
            queryString += " LIMIT \(limit)"
        }
        if debug {
            GlobalLogger.shared.debug("queryString: \(queryString)")
        }
        var selectStatement: OpaquePointer?
        let prepareResult = sqlite3_prepare_v2(sqliteDbPointer, queryString, -1, &selectStatement, nil)
        if prepareResult == SQLITE_OK {
            if let selectStatement = selectStatement {
                return Cursor(selectStatement, debug: debug)
            }
        } else {
            let errorMessage = String.init(cString: sqlite3_errmsg(sqliteDbPointer))
            GlobalLogger.shared.debug("Statement count not prepared, result = \(prepareResult)\nMessage: \(errorMessage)")
        }
        sqlite3_finalize(selectStatement)
        return nil
    }

    // Convenience method for inserting a row into the database.
    /// - Tag: db.insert
    public func insert(table: String, values: ContentValues) -> Int64 {
        var result: Int64 = -1
        var insertRowString = "INSERT INTO \"\(table)\" ("
        for column in values.keySet() {
            insertRowString += "\(column), "
        }
        insertRowString = String(insertRowString.dropLast(2)) + ") VALUES ("
        for value in values.entrySet() {
            insertRowString += "\(value), "
        }
        insertRowString = String(insertRowString.dropLast(2)) + ")"
        if debug {
            GlobalLogger.shared.debug("insertString: \(insertRowString)")
        }
        var insertRowStatement: OpaquePointer?
        let prepareResult = sqlite3_prepare_v2(sqliteDbPointer, insertRowString, -1, &insertRowStatement, nil)
        if prepareResult == SQLITE_OK {
            let stepResult = sqlite3_step(insertRowStatement)
            if stepResult == SQLITE_DONE {
                result = sqlite3_last_insert_rowid(sqliteDbPointer)
            } else {
                let errorMessage = String.init(cString: sqlite3_errmsg(sqliteDbPointer))
                GlobalLogger.shared.debug(errorMessage)
            }
        } else {
            let errorMessage = String.init(cString: sqlite3_errmsg(sqliteDbPointer))
            GlobalLogger.shared.debug(errorMessage)
        }
        sqlite3_finalize(insertRowStatement)
        return result
    }

    // Convenience method for updating rows in the database.
    public func update(table: String, values: ContentValues) -> Int {
        return self.update(table: table, values: values, whereClause: nil)
    }

    /// - Tag: db.update
    public func update(table: String, values: ContentValues, whereClause: String?) -> Int {
        var result: Int = 0
        var updateQueryString = "UPDATE \"\(table)\""
        if values.size() > 0 {
            updateQueryString += " SET "
            for (column, value) in values.iterate() {
                updateQueryString += "\(column) = \(value), "
            }
            updateQueryString = String(updateQueryString.dropLast(2))
        }
        if let whereClause = whereClause {
            updateQueryString += " WHERE \(whereClause)"
        }
        if debug {
            GlobalLogger.shared.debug("updateQueryString: \(updateQueryString)")
        }
        var updateStatement: OpaquePointer?
        let prepareResult = sqlite3_prepare_v2(sqliteDbPointer, updateQueryString, -1, &updateStatement, nil)
        if prepareResult == SQLITE_OK {
            let stepResult = sqlite3_step(updateStatement)
            if stepResult == SQLITE_DONE {
                result = Int(sqlite3_changes(sqliteDbPointer))
            } else {
                let errorMessage = String.init(cString: sqlite3_errmsg(sqliteDbPointer))
                GlobalLogger.shared.debug("impossible to update - step operation returned the following result = \(stepResult)\nMessage: \(errorMessage)")
            }
        } else {
            let errorMessage = String.init(cString: sqlite3_errmsg(sqliteDbPointer))
            GlobalLogger.shared.debug("impossible to update \(table) - Statement count not prepared, result = \(prepareResult)\nMessage: \(errorMessage)")
        }
        sqlite3_finalize(updateStatement)
        return result
    }

    // Convenience method for deleting rows in the database.
    public func delete(table: String, whereClause: String) -> Int {
        let deleteQueryString = "DELETE FROM \"\(table)\" WHERE \(whereClause)"
        var deleteStatement: OpaquePointer?
        if debug {
            GlobalLogger.shared.debug("deleteQueryString: \(deleteQueryString)")
        }
        let prepareResult = sqlite3_prepare_v2(sqliteDbPointer, deleteQueryString, -1, &deleteStatement, nil)
        if prepareResult == SQLITE_OK {
            let stepResult = sqlite3_step(deleteStatement)
            if stepResult == SQLITE_DONE {
                return Int(sqlite3_changes(sqliteDbPointer))
            } else {
                let errorMessage = String.init(cString: sqlite3_errmsg(sqliteDbPointer))
                GlobalLogger.shared.debug("impossible to delete rows from table: \(table) - step operation returned the following result = \(stepResult)\nMessage: \(errorMessage)")
            }
        } else {
            let errorMessage = String.init(cString: sqlite3_errmsg(sqliteDbPointer))
            GlobalLogger.shared.debug("impossible to delete rows from table: \(table) - Statement count not prepared, result = \(prepareResult)\nMessage: \(errorMessage)")
        }
        sqlite3_finalize(deleteStatement)
        return -1
    }

    // Convenience method for deleting table
    public func drop(table: String) -> Bool {
        var result = false
        let dropQueryString = "DROP TABLE IF EXISTS `\(table)`"
        var dropStatement: OpaquePointer?
        if debug {
            GlobalLogger.shared.debug("dropQueryString: \(dropQueryString)")
        }
        let prepareResult = sqlite3_prepare_v2(sqliteDbPointer, dropQueryString, -1, &dropStatement, nil)
        if prepareResult == SQLITE_OK {
            let stepResult = sqlite3_step(dropStatement)
            if stepResult == SQLITE_DONE {
                result = true
            } else {
                let errorMessage = String.init(cString: sqlite3_errmsg(sqliteDbPointer))
                GlobalLogger.shared.debug("impossible to drop table \(table) - step operation returned the following result = \(stepResult)\nMessage: \(errorMessage)")
            }
        } else {
            let errorMessage = String.init(cString: sqlite3_errmsg(sqliteDbPointer))
            GlobalLogger.shared.debug("impossible to drop table \(table) - Statement count not prepared, result = \(prepareResult)\nMessage: \(errorMessage)")
        }
        sqlite3_finalize(dropStatement)
        return result
    }

    // Advanced
    // Transaction, while inserting a load of data
    public func transaction(_ block: () -> Void) {
        beginTransaction()
        block()
        endTransaction()
    }

    private func beginTransaction() {
        if !execSQL("BEGIN TRANSACTION") {
            GlobalLogger.shared.debug("An error occured while trying to launch the transaction.")
        }
    }

    private func endTransaction() {
        if !execSQL("COMMIT") {
            GlobalLogger.shared.debug("An error occured while trying to end the transaction.")
        }
    }

    // Returns true if the current thread has a transaction pending.
    // Auto-Commit mode is enabled by default. So if auto-commit has been disabled it is because
    // there is a transaction active:
    // @see: https://sqlite.org/c3ref/get_autocommit.html
    public func inTransaction() -> Bool {
        return sqlite3_get_autocommit(sqliteDbPointer) == 0
    }

    private func close() {
        sqlite3_close(sqliteDbPointer)
    }
}
