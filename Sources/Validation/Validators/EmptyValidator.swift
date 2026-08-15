import Foundation

extension Validator where T: Collection {
    /// Validates that the data is empty. You can also check a non empty state by combining with the
    /// `NotValidator`
    ///
    ///     try validations.add(\.name, .empty)
    ///     try validations.add(\.name, !.empty)
    ///
    public static var empty: Validator<T> {
        EmptyValidator().validator()
    }
}

// MARK: Private

/// Validates whether the data is empty.
private struct EmptyValidator<T: Collection>: ValidatorType {
    /// See `ValidatorType`.
    var validatorReadable: String {
        "empty"
    }

    /// See `ValidatorType`.
    func validate(_ data: T) throws {
        guard data.isEmpty else {
            throw BasicValidationError("is not empty")
        }
    }
}
