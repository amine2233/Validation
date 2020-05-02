/// A discrete `Validator`. Usually created by calling `ValidatorType.validator()`.
public struct Validator<T>: CustomStringConvertible {
    /// Readable name explaining what this `Validator` does. Must be suitable for placing after `is` _and_ `is not.
    public var readable: String

    /// Validates the supplied `ValidationData`, throwing an error if it is not valid.
    ///
    /// - parameters:
    ///     - data: `ValidationData` to validate.
    /// - throws: `ValidationError` if the data is not valid, or another error if something fails.
    private let closure: (T) throws -> Void

    /// See `CustomStringConvertible`.
    public var description: String {
        return readable
    }

    /// Creates a new `Validation`.
    ///
    /// - parameters:
    ///     - readable: Readable name, suitable for placing after `is` _and_ `is not`.
    ///     - validate: Validates the supplied `ValidationData`, throwing an error if it is not valid.
    public init(_ readable: String, _ closure: @escaping (T) throws -> Void) {
        self.readable = readable
        self.closure = closure
    }

    /// Validates the supplied `ValidationData`, throwing an error if it is not valid.
    ///
    /// - parameters:
    ///     - data: `ValidationData` to validate.
    /// - throws: `ValidationError` if the data is not valid, or another error if something fails.
    public func validate(_ data: T) throws {
        try closure(data)
    }
}
