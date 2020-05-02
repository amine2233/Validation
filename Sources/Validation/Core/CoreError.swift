//
//  CoreError.swift
//  Validation
//
//  Created by Amine Bensalah on 02/05/2020.
//

import Foundation

/// An error that can be thrown while working with the `Core` module.
public struct CoreError: Error {
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
    public init(identifier: String, reason: String, possibleCauses: [String] = [], suggestedFixes: [String] = []) {
        self.identifier = identifier
        self.reason = reason
        self.suggestedFixes = suggestedFixes
        self.possibleCauses = possibleCauses
    }
}

/// Logs an unhandleable runtime error.
internal func ERROR(_ string: @autoclosure () -> String) {
    print("[ERROR] [Core] \(string())")
}
