import Foundation

/// A validation error that supports dynamic key paths. These key paths will be automatically
/// combined to support nested validations.
///
/// See `BasicValidationError` for a default implementation.
public protocol ValidationError: Error, Sendable {
    var path: [String] { get set }

    var reason: String { get }
}

extension ValidationError {
    /// See `Debuggable`.
    public var identifier: String {
        "validationFailed"
    }

    var reason: String {
        ""
    }
}

// MARK: Basic

/// Errors that can be thrown while working with validation
public struct BasicValidationError: ValidationError, Sendable {
    /// See `Debuggable`
    public var reason: String {
        let path = if !self.path.isEmpty {
            "" + self.path.joined(separator: ".") + ""
        } else {
            "data"
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
