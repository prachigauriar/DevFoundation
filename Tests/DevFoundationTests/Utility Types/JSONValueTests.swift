//
//  JSONValueTests.swift
//  DevFoundation
//
//  Created by Prachi Gauriar on 3/20/25.
//

@testable import struct DevFoundation.JSONCodingKey
import DevFoundation
import DevTesting
import Foundation
import Testing


struct JSONValueTests: RandomValueGenerating {
    var randomNumberGenerator = makeRandomNumberGenerator()


    @Test
    func hashableForArrays() {
        let array: JSONValue = [nil, false, 1, "two", .ifPresent(.ifPresent(.number(Float64.pi)))]
        let equal = array
        let unequal: JSONValue = [.ifPresent(.ifPresent(.number(Float64.pi))), "two", 1, false, nil, 0]

        #expect(array == equal)
        #expect(equal == array)
        #expect(array.hashValue == equal.hashValue)

        #expect(array != unequal)
        #expect(unequal != array)
    }


    @Test
    func hashableForBooleans() {
        let boolean: JSONValue = false
        let equal = boolean
        let unequal: JSONValue = true

        #expect(boolean == equal)
        #expect(equal == boolean)
        #expect(boolean.hashValue == equal.hashValue)

        #expect(boolean != unequal)
        #expect(unequal != boolean)
    }


    @Test
    func hashableForIfPresent() {
        let present: JSONValue = .ifPresent(42)
        let presentEqual = present
        let presentUnequal: JSONValue = .ifPresent(false)
        let notPresent: JSONValue = .ifPresent(nil as JSONValue?)

        #expect(present == presentEqual)
        #expect(presentEqual == present)
        #expect(present.hashValue == presentEqual.hashValue)

        #expect(notPresent == notPresent)
        #expect(notPresent.hashValue == notPresent.hashValue)

        #expect(present != presentUnequal)
        #expect(presentUnequal != present)

        #expect(present != notPresent)
        #expect(notPresent != present)
    }


    @Test
    func hashableForNulls() {
        #expect(JSONValue.null == .null)
        #expect(JSONValue.null.hashValue == JSONValue.null.hashValue)
    }


    @Test
    func hashableForNumbers() {
        let number: JSONValue = .number(12345)
        let equal: JSONValue = .number(12345.0)
        let unequal: JSONValue = .number(.unsignedInteger(123456))

        #expect(number == equal)
        #expect(equal == number)
        #expect(number.hashValue == equal.hashValue)

        #expect(number != unequal)
        #expect(unequal != number)
    }


    @Test
    func hashableForObjects() {
        let object: JSONValue = [
            "key1": nil,
            "key2": false,
            "key3": 1,
            "key4": "two",
            "key5": .ifPresent(.ifPresent(.number(Float64.pi)))
        ]
        let equal = object
        let unequal: JSONValue = [
            "key1": .ifPresent(.ifPresent(.number(Float64.pi))),
            "key2": "two",
            "key3": 1,
            "key4": false,
            "key5": nil,
            "key6": 0
        ]

        #expect(object == equal)
        #expect(equal == object)
        #expect(object.hashValue == equal.hashValue)

        #expect(object != unequal)
        #expect(unequal != object)
    }


    @Test
    func hashableForStrings() {
        let string: JSONValue = "spacely"
        let equal = string
        let unequal: JSONValue = "sprockets"

        #expect(string == equal)
        #expect(equal == string)
        #expect(string.hashValue == equal.hashValue)

        #expect(string != unequal)
        #expect(unequal != string)
    }


    @Test
    mutating func jsonValueNumberHashableWhenLHSIsFloatingPoint() {
        let float64 = random(Float64.self, in: 0 ... 100)
        let roundedFloat64 = float64.rounded(.towardZero)

        // Equal
        let floatingPoint = JSONValue.Number.floatingPoint(float64)
        let roundedFloatingPoint = JSONValue.Number.floatingPoint(roundedFloat64)
        let roundedInteger = JSONValue.Number.integer(Int64(roundedFloat64))
        let roundedUnsignedInteger = JSONValue.Number.unsignedInteger(UInt64(roundedFloat64))

        #expect(floatingPoint == floatingPoint)
        #expect(floatingPoint.hashValue == floatingPoint.hashValue)
        #expect(roundedFloatingPoint.hashValue == roundedInteger.hashValue)
        #expect(roundedFloatingPoint.hashValue == roundedUnsignedInteger.hashValue)

        // Not equal
        #expect(floatingPoint != .floatingPoint(float64 * 2))
        #expect(floatingPoint != roundedInteger)
        #expect(floatingPoint != roundedUnsignedInteger)
        #expect(floatingPoint != .integer(.min))
        #expect(floatingPoint != .integer(.max))
        #expect(floatingPoint != .unsignedInteger(.max))
    }


    @Test
    mutating func jsonValueNumberHashableWhenLHSIsInteger() {
        let nonNegativeInt64 = random(Int64.self, in: 0 ... 10_000)
        let negativeInt64 = random(Int64.self, in: -10_000 ..< 0)

        // Equal
        let integer = JSONValue.Number.integer(nonNegativeInt64)
        let negativeInteger = JSONValue.Number.integer(negativeInt64)
        let floatingPoint = JSONValue.Number.floatingPoint(Float64(nonNegativeInt64))
        let unsignedInteger = JSONValue.Number.unsignedInteger(UInt64(nonNegativeInt64))

        #expect(integer == integer)
        #expect(integer.hashValue == integer.hashValue)
        #expect(integer == floatingPoint)
        #expect(integer.hashValue == floatingPoint.hashValue)
        #expect(integer == unsignedInteger)
        #expect(integer.hashValue == unsignedInteger.hashValue)

        // Not equal
        #expect(negativeInteger != integer)
        #expect(negativeInteger != unsignedInteger)
        #expect(negativeInteger != .unsignedInteger(.max))
    }


    @Test
    mutating func jsonValueNumberHashableWhenLHSIsUnsignedInteger() {
        let uint64 = random(UInt64.self, in: 0 ..< 10_000)
        let unequalUInt64 = random(UInt64.self, in: 10_000 ... 100_000)

        // Equal
        let unsignedInteger = JSONValue.Number.unsignedInteger(UInt64(uint64))
        let unequalUnsignedInteger = JSONValue.Number.unsignedInteger(UInt64(unequalUInt64))

        let floatingPoint = JSONValue.Number.floatingPoint(Float64(uint64))
        let integer = JSONValue.Number.integer(Int64(uint64))

        #expect(unsignedInteger == unsignedInteger)
        #expect(unsignedInteger.hashValue == unsignedInteger.hashValue)
        #expect(unsignedInteger == floatingPoint)
        #expect(unsignedInteger.hashValue == floatingPoint.hashValue)
        #expect(unsignedInteger == integer)
        #expect(unsignedInteger.hashValue == integer.hashValue)

        // Not equal
        #expect(unequalUnsignedInteger != integer)
        #expect(unequalUnsignedInteger != unsignedInteger)
        #expect(unequalUnsignedInteger != .integer(.min))
    }
}
