//
//  JSONValue.swift
//  DevFoundation
//
//  Created by Prachi Gauriar on 3/19/25.
//

import Foundation


public indirect enum JSONValue: Sendable {
    /// A JSON numeric value.
    public enum Number: Sendable {
        /// A floating point number.
        case floatingPoint(Float64)

        /// A signed integer.
        case integer(Int64)

        /// An unsigned integer.
        case unsignedInteger(UInt64)
    }


    /// A JSON array
    case array([JSONValue])

    /// A boolean.
    case boolean(Bool)

    /// A value that is only present in a JSON collection if its associated value is non-`nil`.
    case ifPresent(JSONValue?)

    /// Null.
    case null

    /// A number.
    case number(Number)

    /// A JSON object.
    case object([String: JSONValue])

    /// A string.
    case string(String)

    /// Returns the unwrapped JSON value contained within the instance.
    ///
    /// For ``ifPresent`` values, this property returns the value’s assocated value. For all other values, it returns
    /// the value itself.
    var unwrapped: JSONValue? {
        switch self {
        case .ifPresent(let unwrapped):
            return unwrapped
        default:
            return self
        }
    }
}


// MARK: - Codable

extension JSONValue: Codable {
    public init(from decoder: any Decoder) throws {
        if let container = try? decoder.container(keyedBy: JSONCodingKey.self) {
            // Object
            self = .object(
                Dictionary(
                    uniqueKeysWithValues: try container.allKeys.map { (key) in
                        (key.stringValue, try container.decode(JSONValue.self, forKey: key))
                    }
                )
            )
        } else if var container = try? decoder.unkeyedContainer() {
            // Array
            var elements: [JSONValue] = []

            while !container.isAtEnd {
                elements.append(try container.decode(JSONValue.self))
            }

            self = .array(elements)
        } else {
            // Scalars
            let container = try decoder.singleValueContainer()

            if let bool = try? container.decode(Bool.self) {
                self = .boolean(bool)
            } else if container.decodeNil() {
                self = .null
            } else if let number = try? container.decode(Number.self) {
                self = .number(number)
            } else if let string = try? container.decode(String.self) {
                self = .string(string)
            } else {
                throw DecodingError.dataCorrupted(
                    .init(
                        codingPath: decoder.codingPath,
                        debugDescription: "Value is not a valid JSONValue"
                    )
                )
            }
        }
    }


    public func encode(to encoder: any Encoder) throws {
        switch self {
        case .array(let array):
            var container = encoder.unkeyedContainer()
            for element in array {
                guard let unwrwappedValue = element.unwrapped else {
                    continue
                }

                try container.encode(unwrwappedValue)
            }
        case .boolean(let bool):
            var container = encoder.singleValueContainer()
            try container.encode(bool)
        case .ifPresent:
            throw EncodingError.invalidValue(
                self,
                .init(
                    codingPath: encoder.codingPath,
                    debugDescription: "Cannot encode .ifPresent outside of a JSON collection"
                )
            )
        case .null:
            var container = encoder.singleValueContainer()
            try container.encodeNil()
        case .number(let number):
            var container = encoder.singleValueContainer()
            try container.encode(number)
        case .object(let dictionary):
            var container = encoder.container(keyedBy: JSONCodingKey.self)
            for (key, value) in dictionary {
                guard let unwrappedValue = value.unwrapped else {
                    continue
                }

                try container.encode(unwrappedValue, forKey: .init(stringValue: key))
            }
        case .string(let string):
            var container = encoder.singleValueContainer()
            try container.encode(string)
        }
    }
}


extension JSONValue.Number: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let integer = try? container.decode(Int64.self) {
            self = .integer(integer)
        } else if let unsignedInteger = try? container.decode(UInt64.self) {
            self = .unsignedInteger(unsignedInteger)
        } else if let float64 = try? container.decode(Float64.self) {
            self = .floatingPoint(float64)
        } else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: decoder.codingPath,
                    debugDescription: "Invalid JSON number"
                )
            )
        }
    }


    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .floatingPoint(let float64):
            try container.encode(float64)
        case .integer(let int64):
            try container.encode(int64)
        case .unsignedInteger(let uint64):
            try container.encode(uint64)
        }
    }
}


/// A coding key for a JSON object.
struct JSONCodingKey: CodingKey {
    let stringValue: String


    init(stringValue: String) {
        self.stringValue = stringValue
    }


    init?(intValue: Int) {
        return nil
    }


    var intValue: Int? {
        return nil
    }
}


// MARK: - Hashable

extension JSONValue: Hashable {
    public static func ==(lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.array(let left), .array(let right)):
            return left.compactMap(\.unwrapped) == right.compactMap(\.unwrapped)
        case (.boolean(let left), .boolean(let right)):
            return left == right
        case (.ifPresent(let left), let right):
            return left?.unwrapped == right.unwrapped
        case (let left, .ifPresent(let right)):
            return left.unwrapped == right?.unwrapped
        case (.null, .null):
            return true
        case (.number(let left), .number(let right)):
            return left == right
        case (.object(let left), .object(let right)):
            return left.compactMapValues(\.unwrapped) == right.compactMapValues(\.unwrapped)
        case (.string(let left), .string(let right)):
            return left == right
        default:
            return false
        }
    }


    public func hash(into hasher: inout Hasher) {
        switch self {
        case .array(let array):
            hasher.combine(array.compactMap(\.unwrapped))
        case .boolean(let bool):
            hasher.combine(bool)
        case .ifPresent(let jsonValue):
            if let unwrapped = jsonValue?.unwrapped {
                hasher.combine(unwrapped)
            } else {
                hasher.combine(JSONValue?.none)
            }
        case .null:
            hasher.combine(JSONValue?.none)
        case .number(let number):
            hasher.combine(number)
        case .object(let object):
            hasher.combine(object.compactMapValues(\.unwrapped))
        case .string(let string):
            hasher.combine(string)
        }
    }

}


extension JSONValue.Number: Hashable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.floatingPoint(let lhs), .floatingPoint(let rhs)):
            return lhs == rhs
        case (.floatingPoint(let lhs), .integer(let rhs)):
            return lhs == Float64(rhs)
        case (.floatingPoint(let lhs), .unsignedInteger(let rhs)):
            return lhs == Float64(rhs)
        case (.integer(let lhs), .floatingPoint(let rhs)):
            return Float64(lhs) == rhs
        case (.integer(let lhs), .integer(let rhs)):
            return lhs == rhs
        case (.integer(let lhs), .unsignedInteger(let rhs)):
            return lhs < 0 ? false : UInt64(lhs) == rhs
        case (.unsignedInteger(let lhs), .floatingPoint(let rhs)):
            return Float64(lhs) == rhs
        case (.unsignedInteger(let lhs), .integer(let rhs)):
            return rhs < 0 ? false : lhs == UInt64(rhs)
        case (.unsignedInteger(let lhs), .unsignedInteger(let rhs)):
            return lhs == rhs
        }
    }


    public func hash(into hasher: inout Hasher) {
        switch self {
        case .floatingPoint(let value):
            hasher.combine(value)
        case .integer(let value):
            hasher.combine(Float64(value))
        case .unsignedInteger(let value):
            hasher.combine(Float64(value))
        }
    }
}



// MARK: - Convenient Creation

extension JSONValue {
    /// Creates a new `.ifPresent` that wraps an optional boolean.
    ///
    /// This is equivalent to `.ifPresent(value.map(JSONValue.boolean(_:)))`.
    ///
    /// - Parameter value: The optional boolean to wrap.
    public static func ifPresent(_ value: Bool?) -> JSONValue {
        return .ifPresent(value.map(JSONValue.boolean(_:)))
    }


    /// Creates a new `.ifPresent` that wraps an optional binary floating point.
    ///
    /// This is equivalent to `.ifPresent(value.map(JSONValue.number(_:)))`.
    ///
    /// - Parameter value: The optional binary floating point to wrap.
    public static func ifPresent(_ value: (some BinaryFloatingPoint)?) -> JSONValue {
        return .ifPresent(value.map(JSONValue.number(_:)))
    }


    /// Creates a new `.ifPresent` that wraps an optional signed integer.
    ///
    /// This is equivalent to `.ifPresent(value.map(JSONValue.number(_:)))`.
    ///
    /// - Parameter value: The optional binary floating point to wrap.
    public static func ifPresent(_ integer: (some SignedInteger)?) -> JSONValue {
        return .ifPresent(integer.map(JSONValue.number(_:)))
    }


    /// Creates a new `.ifPresent` that wraps an optional string.
    ///
    /// This is equivalent to `.ifPresent(value.map(JSONValue.number(_:)))`.
    ///
    /// - Parameter value: The optional unsigned integer to wrap.
    public static func ifPresent(_ string: String?) -> JSONValue {
        return .ifPresent(string.map(JSONValue.string(_:)))
    }


    /// Creates a new `.ifPresent` that wraps an optional unsigned integer.
    ///
    /// This is equivalent to `.ifPresent(value.map(JSONValue.number(_:)))`.
    ///
    /// - Parameter value: The optional unsigned integer to wrap.
    public static func ifPresent(_ value: (some UnsignedInteger)?) -> JSONValue {
        return .ifPresent(value.map(JSONValue.number(_:)))
    }


    /// Creates a new `.number` with the given binary floating point value.
    ///
    /// - Parameter value: The binary floating-point value.
    public static func number(_ value: some BinaryFloatingPoint) -> JSONValue {
        return .number(.floatingPoint(Float64(value)))
    }


    /// Creates a new `.number` with the given signed integer value.
    ///
    /// - Parameter value: The signed integer value.
    public static func number(_ value: some SignedInteger) -> JSONValue {
        return .number(.integer(Int64(value)))
    }


    /// Creates a new `.number` with the given unsigned integer value.
    ///
    /// - Parameter value: The unsigned integer value.
    public static func number(_ value: some UnsignedInteger) -> JSONValue {
        return .number(.unsignedInteger(UInt64(value)))
    }
}


// MARK: - Literals

extension JSONValue: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: JSONValue...) {
        self = .array(elements)
    }
}


extension JSONValue: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self = .boolean(value)
    }
}


extension JSONValue: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, JSONValue)...) {
        self = .object(Dictionary(elements, uniquingKeysWith: { (value1, value2) in value2 }))
    }
}


extension JSONValue: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Float64) {
        self = .number(.floatingPoint(value))
    }
}


extension JSONValue: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int64) {
        self = .number(.integer(value))
    }
}


extension JSONValue: ExpressibleByNilLiteral {
    public init(nilLiteral: Void) {
        self = .null
    }
}


extension JSONValue: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}
