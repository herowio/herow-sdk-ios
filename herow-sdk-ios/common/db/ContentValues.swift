//
//  ContentValues.swift
//  SQLiteDatabase
//
//  Created by Ludovic Vimont on 11/09/2019.
//  Copyright © 2019 Connecthings. All rights reserved.
//

import Foundation

/// A dictionary used to [insert](x-source-tag://db.insert) or [update](x-source-tag://db.update) data within a query
public class ContentValues: CustomStringConvertible {
    private var values = [String: Any]()

    public init() {}

    public func put(key: String, value: String) {
        values[key] = DbHelper.addingSQLEscapes(value)
    }

    public func put(key: String, value: Bool) {
        values[key] = value
    }

    public func put(key: String, value: Int) {
        values[key] = value
    }

    public func put(key: String, value: Int8) {
        values[key] = value
    }

    public func put(key: String, value: Int16) {
        values[key] = value
    }

    public func put(key: String, value: Int32) {
        values[key] = value
    }

    public func put(key: String, value: Int64) {
        values[key] = value
    }

    public func put(key: String, value: UInt) {
        values[key] = value
    }

    public func put(key: String, value: UInt8) {
        values[key] = value
    }

    public func put(key: String, value: UInt16) {
        values[key] = value
    }

    public func put(key: String, value: UInt32) {
        values[key] = value
    }

    public func put(key: String, value: UInt64) {
        values[key] = value
    }

    public func put(key: String, value: Float) {
        values[key] = value
    }

    public func put(key: String, value: Double) {
        values[key] = value
    }

    public func put(key: String, value: Character) {
        values[key] = value
    }

    public func putNull(key: String) {
        values[key] = nil
    }

    public func size() -> Int {
        return values.count
    }

    public func isEmpty() -> Bool {
        return values.isEmpty
    }

    public func remove(key: String) {
        values.removeValue(forKey: key)
    }

    public func clear() {
        values.removeAll()
    }

    public func containsKey(_ key: String) -> Bool {
        return values.keys.contains(key)
    }

    public func get(_ key: String) -> Any? {
        return values[key]
    }

    public func getAsString(_ key: String) -> String? {
        if let value = get(key) as? String {
            return value
        }
        return nil
    }

    public func getAsBoolean(_ key: String) -> Bool? {
        if let value = get(key) as? Bool {
            return value
        }
        return nil
    }

    public func getAsInt(_ key: String) -> Int? {
        if let value = get(key) as? Int {
            return value
        }
        return nil
    }

    public func getAsInt8(_ key: String) -> Int8? {
        if let value = get(key) as? Int8 {
            return value
        }
        return nil
    }

    public func getAsInt16(_ key: String) -> Int16? {
        if let value = get(key) as? Int16 {
            return value
        }
        return nil
    }

    public func getAsInt32(_ key: String) -> Int32? {
        if let value = get(key) as? Int32 {
            return value
        }
        return nil
    }

    public func getAsInt64(_ key: String) -> Int64? {
        if let value = get(key) as? Int64 {
            return value
        }
        return nil
    }

    public func getAsUInt(_ key: String) -> UInt? {
        if let value = get(key) as? UInt {
            return value
        }
        return nil
    }

    public func getAsUInt8(_ key: String) -> UInt8? {
        if let value = get(key) as? UInt8 {
            return value
        }
        return nil
    }

    public func getAsUInt16(_ key: String) -> UInt16? {
        if let value = get(key) as? UInt16 {
            return value
        }
        return nil
    }

    public func getAsUInt32(_ key: String) -> UInt32? {
        if let value = get(key) as? UInt32 {
            return value
        }
        return nil
    }

    public func getAsUInt64(_ key: String) -> UInt64? {
        if let value = get(key) as? UInt64 {
            return value
        }
        return nil
    }

    public func getAsDouble(_ key: String) -> Double? {
        if let value = get(key) as? Double {
            return value
        }
        return nil
    }

    public func getAsFloat(_ key: String) -> Float? {
        if let value = get(key) as? Float {
            return value
        }
        return nil
    }

    public func getAsCharacter(_ key: String) -> Character? {
        if let value = get(key) as? Character {
            return value
        }
        return nil
    }

    public func iterate() -> [String: Any] {
        return values
    }

    public func keySet() -> Dictionary<String, Any>.Keys {
        return values.keys
    }

    public func entrySet() -> Dictionary<String, Any>.Values {
        return values.values
    }

    public var description: String {
        var result = "ContentValues - \(Unmanaged.passUnretained(self).toOpaque()) [\n"
        for (key, value) in values {
            result += "\t\(key) - \(value)\n"
        }
        result += "]"
        return result
    }
}
