//
//  DataHolderUserDefaults.swift
//  ConnectPlaceCommon
//
//  Created by Amine GAHBICHE on 19/02/2018.
//  Copyright © 2018 Connecthings. All rights reserved.
//

import Foundation

@objc public class DataHolderUserDefaults: NSObject, DataHolderObjc {
    private var dhUserDefaults: UserDefaults

    public init(suiteName: String) {
        if let userDefaults = UserDefaults(suiteName: suiteName) {
            dhUserDefaults = userDefaults
        } else {
            dhUserDefaults = UserDefaults.standard
        }
    }

    public init(userDefaults: UserDefaults) {
        self.dhUserDefaults = userDefaults
    }

    public func putFloat(key: String, value: Float) {
        dhUserDefaults.set(value, forKey: key)
    }

    public func getFloat(key: String) -> Float {
        return dhUserDefaults.float(forKey: key)
    }

    public func putDouble(key: String, value: Double) {
        dhUserDefaults.set(value, forKey: key)
    }

    public func getDouble(key: String) -> Double {
        return dhUserDefaults.double(forKey: key)
    }

    public func putInt(key: String, value: Int) {
        dhUserDefaults.set(value, forKey: key)
    }

    public func getInt(key: String) -> Int {
        return dhUserDefaults.integer(forKey: key)
    }

    public func putBoolean(key: String, value: Bool) {
        dhUserDefaults.set(value, forKey: key)
    }

    public func getBoolean(key: String) -> Bool {
        return dhUserDefaults.bool(forKey: key)
    }

    public func putString(key: String, value: String) {
        dhUserDefaults.set(value, forKey: key)
    }

    public func getString(key: String) -> String? {
        return dhUserDefaults.string(forKey: key)
    }

    public func putData(key: String, value: Data) {
        dhUserDefaults.set(value, forKey: key)
    }

    public func getData(key: String) -> Data? {
        return dhUserDefaults.data(forKey: key)
    }

    public func putDate(key: String, value: Date) {
        dhUserDefaults.set(value, forKey: key)
    }

    public func getDate(key: String) -> Date? {
        return dhUserDefaults.value(forKey: key) as? Date
    }


    public func saveNSCodingObject(key: String, value: Any) {
        if value is NSCoding {
            let dataToSave: Data = NSKeyedArchiver.archivedData(withRootObject: value)
            dhUserDefaults.set(dataToSave, forKey: key)
        } else {
            GlobalLogger.shared.warning("The object does not conform to NSCoding. Please implement NSCoding or use saveCodableObject for types conforming to Codable protocol")
        }
    }

    public func loadNSCodingObject(key: String) -> Any? {
        if let retrievedData: Data = dhUserDefaults.object(forKey: key) as? Data {
            return NSKeyedUnarchiver.unarchiveObject(with: retrievedData)
        } else {
            return nil
        }
    }

    public func clear() {
        let dict = dhUserDefaults.dictionaryRepresentation()
        for key in dict.keys {
            dhUserDefaults.removeObject(forKey: key)
        }
    }

    public func apply() {
        dhUserDefaults.synchronize()
    }

    public func contains(key: String) -> Bool {
        if let _ = dhUserDefaults.object(forKey: key) {
            return true
        } else {
            return false
        }
    }

    public func remove(key: String) {
        dhUserDefaults.removeObject(forKey: key)
    }

    public func removeAll() {
        clear()
        apply()
    }

}

@nonobjc extension DataHolderUserDefaults: DataHolderCodable {
    @nonobjc public func saveCodableObject<EncodableType>(key: String, value: EncodableType)
        where EncodableType: Encodable {
            do {
                let dataToSave = try PropertyListEncoder().encode(value)
                dhUserDefaults.set(dataToSave, forKey: key)
            } catch {
                GlobalLogger.shared.error(error)
            }
    }

    @nonobjc public func loadCodableObject<T>(codableType: T.Type, key: String) -> T? where T: Decodable {
        if let retrievedData: Data = dhUserDefaults.object(forKey: key) as? Data {
            do {
                let result: T = try PropertyListDecoder().decode(codableType, from: retrievedData)
                return result
            } catch {
                GlobalLogger.shared.error(error)
            }
        }
        return nil
    }
}

extension DataHolderUserDefaults: GenericHolder {

}
