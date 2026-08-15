import Foundation

public protocol ValidatorType: Sendable {
    /// Data type to validate
    associatedtype ValidationData

    /// Readable name explaining what this `Validator` does. Suitable for placing after `is` _and_ `is not`.
    ///
    ///     is alphanumeric
    ///     is not alphanumeric
    ///
    var validatorReadable: String { get }

    /// Validates the supplied `ValidationData`, throwing an error if it is not valid.
    ///
    /// - parameters:
    ///     - data: `ValidationData` to validate.
    /// - throws: `ValidationError` if the data is not valid, or another error if something fails.
    func validate(_ data: ValidationData) throws
}

extension ValidatorType {
    /// Create a `Validator` for this `ValidatorType`.
    public func validator() -> Validator<ValidationData> {
        Validator(validatorReadable, validate)
    }
}
