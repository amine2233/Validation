import Foundation

public struct Validations<M: Sendable & Validatable>: CustomStringConvertible, Sendable {
    /// Internal storage
    fileprivate var storage: [Validator<M>]

    /// See `CustomStringConvertible`.
    public var description: String {
        storage.map { $0.description }.joined(separator: "\n")
    }

    /// Create an empty `Validations` struct. You can also use an empty array `[]`.
    public init(_ model: M.Type) {
        self.storage = []
    }

    /// Adds a new `Validation` at the supplied key path and readable path.
    ///
    ///     try validations.add(\.name, at: ["name"], .count(5...) && .alphanumeric)
    ///
    /// - parameters:
    ///     - keyPath: `KeyPath` to validatable property.
    ///     - path: Readable path. Will be displayed when showing errors.
    ///     - validation: `Validation` to run on this property.
    public mutating func add<T: Sendable>(
        _ keyPath: KeyPath<M, T>,
        at path: [String],
        _ validator: Validator<T>
    ) {
        add(keyPath, at: path, "is " + validator.readable) { value in
            try validator.validate(value)
        }
    }

    /// Adds a custom `Validation` at the supplied key path and readable path.
    ///
    ///     try validations.add(\.name, at: ["name"], "is vapor") { name in
    ///         guard name == "vapor" else { throw }
    ///     }
    ///
    /// - parameters:
    ///     - keyPath: `KeyPath` to validatable property.
    ///     - path: Readable path. Will be displayed when showing errors.
    ///     - readable: Readable string describing this validation.
    ///     - custom: Closure accepting the `KeyPath`'s value. Throw a `ValidationError` here if the data is
    /// invalid.
    public mutating func add<T: Sendable>(
        _ keyPath: KeyPath<M, T>,
        at path: [String],
        _ readable: String,
        custom: @escaping @Sendable (T) throws -> Void
    ) {
        // Key paths are immutable, thread-safe value types, but the stdlib doesn't
        // declare `KeyPath: Sendable`, so it can't be captured directly in the
        // `@Sendable` validator closure. The box bridges that gap.
        let keyPath = UncheckedSendable(keyPath)
        add("\(path.joined(separator: ".")): \(readable)") { model in
            do {
                try custom(model[keyPath: keyPath.value])
            } catch var error as ValidationError {
                error.path += path
                throw error
            }
        }
    }

    /// Adds a custom `Validation` to the `Validations`.
    ///
    ///     try validations.add("name: is vapor") { model in
    ///         guard model.name == "vapor" else { throw }
    ///     }
    ///
    /// - parameters:
    ///     - readable: Readable string describing this validation.
    ///     - custom: Closure accepting an instance of the model. Throw a `ValidationError` here if the model
    /// is invalid.
    public mutating func add(_ redable: String, _ custom: @escaping @Sendable (M) throws -> Void) {
        storage.append(Validator<M>(redable, custom))
    }

    /// Runs the `Validation`s on an instance of `M`.
    public func run(on model: M) throws {
        var errors: [ValidationError] = []
        for validation in storage {
            do {
                try validation.validate(model)
            } catch let error as ValidationError {
                errors.append(error)
            }
        }

        if !errors.isEmpty {
            throw ValidateErrors(errors)
        }
    }
}

extension Validations where M: Reflectable {
    /// Adds a new `Validation` at the supplied key path. Readable path will be reflected.
    ///
    ///     try validations.add(\.name, .count(5...) && .alphanumeric)
    ///
    /// - parameters:
    ///     - keyPath: `KeyPath` to validatable property.
    ///     - validation: `Validation` to run on this property.
    public mutating func add<T: Sendable>(_ keyPath: KeyPath<M, T>, _ validator: Validator<T>) throws {
        try add(keyPath, at: M.reflectProperty(forKey: keyPath)?.path ?? [], validator)
    }

    /// Adds a new custom `Validation` at the supplied key path. Readable path will be reflected.
    ///
    ///     try validations.add(\.name, "is vapor") { name in
    ///         guard name == "vapor" else { throw }
    ///     }
    ///
    /// - parameters:
    ///     - keyPath: `KeyPath` to validatable property.
    ///     - readable: Readable string describing this validation.
    ///     - custom: Closure accepting the `KeyPath`'s value. Throw a `ValidationError` here if the data is
    /// invalid.
    public mutating func add<T: Sendable>(
        _ keyPath: KeyPath<M, T>,
        _ readable: String,
        _ custom: @escaping @Sendable (T) throws -> Void
    ) throws {
        try add(keyPath, at: M.reflectProperty(forKey: keyPath)?.path ?? [], readable, custom: custom)
    }
}

// MARK: Private

/// Wraps a value that is known to be safe to share across concurrency domains but
/// whose type doesn't (yet) declare `Sendable` — used here to capture a `KeyPath`
/// (an immutable, thread-safe value type) inside a `@Sendable` closure.
struct UncheckedSendable<Value>: @unchecked Sendable {
    let value: Value
    init(_ value: Value) {
        self.value = value
    }
}

/// A collection of errors thrown by validatable models validations
private struct ValidateErrors: ValidationError {
    /// the errors throw
    var errors: [ValidationError]

    /// See ValidationError.keyPath
    var path: [String]

    /// See ValidationError.reason
    var reason: String {
        errors.map { error in
            var mutableError = error
            mutableError.path = path + error.path
            return mutableError.reason
        }
        .joined(separator: ", ")
    }

    /// creates a new validatable error
    init(_ errors: [ValidationError]) {
        self.errors = errors
        self.path = []
    }
}
