//
//  DataHolder.swift
//  ConnectPlaceCommon
//
//  Created by Amine GAHBICHE on 19/02/2018.
//  Copyright © 2018 Connecthings. All rights reserved.
//

import Foundation

public typealias DataHolder = DataHolderObjc & DataHolderCodable & GenericHolder

/// Generic interface to save/load key/value sets
@objc public protocol DataHolderObjc {
    /**
     * Set a float value to be written back
     *
     * @param key   The name of the property to modify.
     * @param value The new value for the property.
     */
    func putFloat(key: String, value: Float)
    /**
     * @param key the name of the property to retrieve
     * @return the preference value if it exists, or 0.f.
     */
    func getFloat(key: String) -> Float

    func putDouble(key: String, value: Double)

    func getDouble(key: String) -> Double
    /**
     * Set an int value to be written back
     *
     * @param key   The name of the property to modify.
     * @param value The new value for the property.
     */
    func putInt(key: String, value: Int)
    /**
     * @param key the name of the property to retrieve
     * @return the preference value if it exists, or 0.
     */
    func getInt(key: String) -> Int
    /**
     * Set a boolean value to be written back
     *
     * @param key   The name of the property to modify.
     * @param value The new value for the property.
     */
    func putBoolean(key: String, value: Bool)
    /**
     * @param key the name of the property to retrieve
     * @return the preference value if it exists, or false.
     */
    func getBoolean(key: String) -> Bool
    /**
     * Set a String value to be written back
     *
     * @param key   The name of the property to modify.
     * @param value The new value for the property.
     */
    func putString(key: String, value: String)
    /**
     * @param key the name of the property to retrieve
     * @return the preference value if it exists, or nil.
     */
    func getString(key: String) -> String?
    /**
     * Set a Data value to be written back
     *
     * @param key   The name of the property to modify.
     * @param value The new value for the property.
     */
    func putData(key: String, value: Data)
    /**
     * @param key the name of the property to retrieve
     * @return the preference value if it exists, or nil.
     */
    func getData(key: String) -> Data?
    /**
     * Set an object to be written back. The object need to conform to NSCoding protocol to be saved
     *
     * @param key   The name of the property to modify.
     * @param value The new value for the property.
     */
    func saveNSCodingObject(key: String, value: Any)
    /**
     * @param key the name of the property to retrieve
     * @return the preference value if it exists, or nil.
     */
    func loadNSCodingObject(key: String) -> Any?
    /**
     *
     * @param key
     * @return true if the key is in the dataHolder
     */


    func putDate(key: String, value: Date)

    func getDate(key: String) -> Date?

    func contains(key: String) -> Bool

    func remove(key: String)
    
    func removeAll()
}

public protocol DataHolderCodable {
    /**
     * Set an object to be written back. The object need to conform to Encodable protocol to be saved
     *
     * @param key   The name of the property to modify.
     * @param value The new value for the property.
     */
    func saveCodableObject<EncodableType>(key: String, value: EncodableType) where EncodableType: Encodable
    /**
     * @param codableType the type of the object to retrieve
     * @param key the key of the object to retrieve
     * @return the preference value if it exists, or nil.
     */
    func loadCodableObject<T>(codableType: T.Type, key: String) -> T? where T: Decodable

}
