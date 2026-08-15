import Foundation

/// An error that can be thrown while working with the `Core` module.
public struct CoreError: Error, Sendable {
    /// See `Debuggable`
    public var identifier: String

    /// See `Debuggable`
    public var reason: String

    /// See `Debuggable`
    public var possibleCauses: [String]

    /// See `Debuggable`
    public var suggestedFixes: [String]

    /// Creates a new `CoreError`.
    ///
    /// See `Debuggable`
    public init(
        identifier: String,
        reason: String,
        possibleCauses: [String] = [],
        suggestedFixes: [String] = []
    ) {
        self.identifier = identifier
        self.reason = reason
        self.suggestedFixes = suggestedFixes
        self.possibleCauses = possibleCauses
    }
}

/// Logs an unhandleable runtime error.
func ERROR(_ string: @autoclosure () -> String) {
    print("[ERROR] [Core] \(string())")
}
