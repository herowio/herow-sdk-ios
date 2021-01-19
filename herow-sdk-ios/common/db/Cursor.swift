//
//  Cursor.swift
//  SQLiteDatabase
//
//  Created by Ludovic Vimont on 11/09/2019.
//  Copyright © 2019 Connecthings. All rights reserved.
//

import Foundation
import SQLite3

typealias SQLiteStatementPointer = OpaquePointer

/// A Cursor is the result of an already executed SQL query, you will only have a cursor
/// if the query return an SQLITE_OK.
public class Cursor: CustomStringConvertible {
    fileprivate let sqliteStatement: SQLiteStatementPointer
    private let parameterCount: Int
    private var debug: Bool
    private var columnNames = [String]()

    init(_ sqliteStatement: SQLiteStatementPointer, debug: Bool = false) {
        self.sqliteStatement = sqliteStatement
        self.debug = debug
        self.parameterCount = Int(sqlite3_bind_parameter_count(sqliteStatement))
        self.columnNames = extractColumnNames()
    }

    deinit {
        self.close()
    }

    private func extractColumnNames() -> [String] {
        var columnNames = [String]()
        let columnCount = sqlite3_column_count(sqliteStatement)
        for columnIndex in 0..<columnCount {
            let columnName = sqlite3_column_name(sqliteStatement, columnIndex)
            if columnName != nil {
                if let columnNameString = NSString(utf8String: columnName!) {
                    columnNames.append(columnNameString as String)
                    continue
                }
            }
            // Add an empty string so the column indices stay the same
            columnNames.append("")
        }
        if columnNames.count != columnCount && debug {
            let warningMessage = """
            /!\\, they seems to have a difference between the column size return by the sqliteStatement
            and the extracted columns name
            """
            GlobalLogger.shared.debug(warningMessage)
        }
        return columnNames
    }

    /**
     * Move the cursor to the next row.
     *
     * <p>This method will return false if the cursor is already past the
     * last entry in the result set.
     *
     * @return whether the move succeeded.
     */
    public func moveToNext() -> Bool {
        switch sqlite3_step(sqliteStatement) {
        case SQLITE_DONE:
            return false
        case SQLITE_ROW:
            return true
        case SQLITE_BUSY:
            if debug {
                GlobalLogger.shared.debug("SQLITE_BUSY error has been raised !")
            }
            return false
        case SQLITE_ERROR:
            if debug {
                GlobalLogger.shared.debug("SQLITE_ERROR error has been raised !")
            }
            return false
        default:
            return false
        }
    }

    /**
     * Returns the zero-based index for the given column name, or -1 if the column doesn't exist.
     *
     * @param columnName the name of the target column.
     * @return the zero-based column index for the given column name, or -1 if
     * the column name does not exist.
     */
    public func getColumnIndex(columnName: String) -> Int {
        return columnNames.firstIndex(of: columnName) ?? -1
    }

    /**
     * Returns the column name at the given zero-based column index.
     *
     * @param columnIndex the zero-based index of the target column.
     * @return the column name for the given column index.
     */
    public func getColumnName(columnIndex: Int) -> String {
        return columnNames[columnIndex]
    }

    /**
     * Returns a string array holding the names of all of the columns in the
     * result set in the order in which they were listed in the result.
     *
     * @return the names of the columns returned in this query.
     */
    public func getColumnNames() -> [String] {
        return columnNames
    }

    /**
     * Return total number of columns
     * @return number of columns
     */
    public func getColumnCount() -> Int {
        return columnNames.count
    }

    public func getString(columnIndex: Int) -> String? {
        guard let columnText = sqlite3_column_text(sqliteStatement, Int32(columnIndex)) else {
            return nil
        }
        let columnTextI = UnsafeRawPointer(columnText).assumingMemoryBound(to: Int8.self)
        return NSString(utf8String: columnTextI) as String?
    }

    public func getInt(columnIndex: Int) -> Int? {
        if sqlite3_column_type(sqliteStatement, Int32(columnIndex)) == SQLITE_NULL {
            return nil
        }
        return Int(sqlite3_column_int64(sqliteStatement, Int32(columnIndex)))
    }

    public func getInt64(columnIndex: Int) -> Int64? {
        if sqlite3_column_type(sqliteStatement, Int32(columnIndex)) == SQLITE_NULL {
            return nil
        }
        return sqlite3_column_int64(sqliteStatement, Int32(columnIndex))
    }

    public func getBool(columnIndex: Int) -> Bool? {
        if let intValue = getInt(columnIndex: columnIndex) {
            return intValue != 0
        } else {
            return nil
        }
    }

    public func getFloat(columnIndex: Int) -> Float? {
        if sqlite3_column_type(sqliteStatement, Int32(columnIndex)) == SQLITE_NULL {
            return nil
        }
        return Float(sqlite3_column_double(sqliteStatement, Int32(columnIndex)))
    }

    public func getDouble(columnIndex: Int) -> Double? {
        if sqlite3_column_type(sqliteStatement, Int32(columnIndex)) == SQLITE_NULL {
            return nil
        }
        return sqlite3_column_double(sqliteStatement, Int32(columnIndex))
    }

    /**
     * Closes the Cursor, releasing all of its resources.
     */
    private func close() {
        sqlite3_finalize(sqliteStatement)
    }

    public var description: String {
        var result = "Cursor - \(Unmanaged.passUnretained(self).toOpaque()) [\n"
        for (index, column) in columnNames.enumerated() {
            let type = Int(sqlite3_column_type(sqliteStatement, Int32(index)))
            switch type {
            case SQLiteDatatype.integer.rawValue:
                result += "\t\(column) - \(getInt(columnIndex: index) ?? -1)\n"
            case SQLiteDatatype.float.rawValue:
                result += "\t\(column) - \(getFloat(columnIndex: index) ?? 0.0)\n"
            case SQLiteDatatype.text.rawValue:
                result += "\t\(column) - \(getString(columnIndex: index) ?? "")\n"
            default:
                break
            }
        }
        result += " ]"
        return result
    }
}
