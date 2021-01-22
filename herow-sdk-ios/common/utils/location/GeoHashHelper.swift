//
//  GeoHashHelper.swift
//  HerowConnection
//
//  Created by Ludovic Vimont on 18/09/2019.
//  Copyright © 2019 Connecthings. All rights reserved.
//

import Foundation
import CoreLocation


public class GeoHashHelper {
    // Ascii value of 'z' +1
    private static let asciiValueOfZ = 132

    private static let BASE32: [Character] = [
        "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
        "b", "c", "d", "e", "f", "g", "h", "j", "k", "m",
        "n", "p", "q", "r", "s", "t", "u", "v", "w", "x",
        "y", "z"
    ]

    private static var BASE32_INV: [Int] = {
        var table = [Int]()
        for i in 0...asciiValueOfZ-1 {
            table.append(0)
        }
        for i in 0...BASE32.count-1 {
            if let asciiValueOfCharacter = BASE32[i].asciiValue {
                let characterIndex = Int(asciiValueOfCharacter)
                table[characterIndex] = i
            }
        }
        return table
    }()

    /**
     * Takes a lat/lng and a precision, and returns a 64-bit long containing that
     * many low-order bits (big-endian). You can convert this long to a base-32
     * string using {@link #toBase32}.
     * <p>
     * This function doesn't validate preconditions, which are the following:
     * <p>
     * 1. lat ∈ [-90, 90)
     * 2. lng ∈ [-180, 180)
     * 3. bits ∈ [0, 61]
     * <p>
     * Results are undefined if these preconditions are not met.
     */
    private static func encode(lat: Double, lng: Double, bits: UInt64) -> UInt64 {
        let lats = widen(low32: UInt64((lat + 90) * 0x80000000 / 180.0))
        let lngs = widen(low32: UInt64((lng + 180) * 0x80000000 / 360.0))
        return (lats >> 1 | lngs) >> (61 - bits) | precisionTag(bits: bits)
    }

    private static func precisionTag(bits: UInt64) -> UInt64 {
        return 0x4000000000000000 | 1 << bits
    }

    /**
     * Takes an encoded geohash (as a long) and its precision, and returns a
     * base-32 string representing it. The precision must be a multiple of 5 for
     * this to be accurate.
     */
    private static func toBase32(gh: UInt64, bits: UInt64) -> String {
        var newGh = gh
        var chars = [Character]()
        for _ in 0...Int(bits / 5)-1 {
            chars.append("0")
        }
        for i in stride(from: chars.count-1, to: -1, by: -1) {
            let index = Int(newGh & 0x1f)
            chars[i] = BASE32[index]
            newGh >>= 5
        }
        return String(chars)
    }

    public static func encodeBase32(lat: Double, lng: Double) -> String {
        let bits = UInt64(5 * 12)
        return toBase32(gh: encode(lat: lat, lng: lng, bits: bits), bits: bits)
    }

    /**
     * Takes a latitude, longitude, and precision, and returns a base-32 string
     * representing the encoded geohash. See {@link #encode} and {@link
     * #toBase32} for preconditions (but they're pretty obvious).
     */
    public static func encodeBase32(lat: Double, lng: Double, bits: UInt64) -> String {
        return toBase32(gh: encode(lat: lat, lng: lng, bits: bits), bits: bits)
    }

    /**
     * Takes a base-32 string and returns an object representing its decoding.
     */
    public static func decodeBase32(base32: String) -> CLLocation {
        return decode(gh: fromBase32(base32: base32), bits: UInt64(base32.count * 5))
    }

    public static func decode(gh: UInt64, bits: UInt64) -> CLLocation {
        let shifted = gh << (61 - bits)
        let lat = Double(unwiden(wide: shifted >> 1) & 0x3fffffff) / 0x40000000 * 180 - 90
        let lng = Double(unwiden(wide: shifted) & 0x7fffffff) / 0x80000000 * 360 - 180
        return CLLocation.init(latitude: lat, longitude: lng)
    }

    /**
     * Takes a base-32 string and returns a long containing its bits.
     */
    private static func fromBase32(base32: String) -> UInt64 {
        var result: UInt64 = 0
        for i in 0...base32.count-1 {
            result <<= 5
            let character = base32[i] as Character
            if let characterAsciiValue = character.asciiValue {
                result |= UInt64(BASE32_INV[Int(characterAsciiValue)])
            }
        }
        result = result | precisionTag(bits: UInt64(base32.count * 5))
        return result
    }

    /**
     * "Widens" each bit by creating a zero to its left. This is the first step
     * in interleaving values. @see: https://graphics.stanford.edu/~seander/bithacks.html#InterleaveBMN
     */
    private static func widen(low32: UInt64) -> UInt64 {
        var widenLow32 = low32
        widenLow32 |= widenLow32 << 16
        widenLow32 &= 0x0000ffff0000ffff
        widenLow32 |= widenLow32 << 8
        widenLow32 &= 0x00ff00ff00ff00ff
        widenLow32 |= widenLow32 << 4
        widenLow32 &= 0x0f0f0f0f0f0f0f0f
        widenLow32 |= widenLow32 << 2
        widenLow32 &= 0x3333333333333333
        widenLow32 |= widenLow32 << 1
        widenLow32 &= 0x5555555555555555
        return widenLow32
    }

    /**
     * "Unwidens" each bit by removing the zero from its left. This is the
     * inverse of "widen". @see: http://fgiesen.wordpress.com/2009/12/13/decoding-morton-codes/
     */
    private static func unwiden(wide: UInt64) -> UInt64 {
        var unwidenWide = wide
        unwidenWide &= 0x5555555555555555
        unwidenWide ^= unwidenWide >> 1
        unwidenWide &= 0x3333333333333333
        unwidenWide ^= unwidenWide >> 2
        unwidenWide &= 0x0f0f0f0f0f0f0f0f
        unwidenWide ^= unwidenWide >> 4
        unwidenWide &= 0x00ff00ff00ff00ff
        unwidenWide ^= unwidenWide >> 8
        unwidenWide &= 0x0000ffff0000ffff
        unwidenWide ^= unwidenWide >> 16
        unwidenWide &= 0x00000000ffffffff
        return unwidenWide
    }
}

