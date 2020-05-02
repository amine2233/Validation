//
//  ValidationError.swift
//  Validation
//
//  Created by Amine Bensalah on 02/05/2020.
//

import Foundation

/// A validation error that supports dynamic key paths. These key paths will be automatically
/// combined to support nested validations.
///
/// See `BasicValidationError` for a default implementation.
public protocol ValidationError: Error {
    var path: [String] { get set }

    var reason: String { get }
}

extension ValidationError {
    /// See `Debuggable`.
    public var identifier: String {
        return "validationFailed"
    }

    var reason: String {
        return ""
    }
}

// MARK: Basic

/// Errors that can be thrown while working with validation
public struct BasicValidationError: ValidationError {
    /// See `Debuggable`
    public var reason: String {
        let path: String
        if self.path.count > 0 {
            path = "" + self.path.joined(separator: ".") + ""
        } else {
            path = "data"
        }
        return "\(path) \(message)"
    }

    /// The validation failure
    public var message: String

    /// Key path the validation error happened at
    public var path: [String]

    /// Create a new JWT error
    public init(_ message: String) {
        self.message = message
        self.path = []
    }
}
