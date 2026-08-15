import Foundation

extension Validator where T: Equatable & Sendable {
    /// Validates whether an item is contained in the supplied array.
    ///
    ///     try validations.add(\.name, .in("foo", "bar"))
    ///
    public static func `in`(_ array: T...) -> Validator<T> {
        .in(array)
    }

    /// Validates whether an item is contained in the supplied array.
    ///
    ///     try validations.add(\.name, .in(["foo", "bar"]))
    ///
    public static func `in`(_ array: [T]) -> Validator<T> {
        InValidator(array).validator()
    }
}

// MARK: Private

/// Validates whether an item is contained in the supplied array.
private struct InValidator<T: Equatable & Sendable>: ValidatorType {
    /// See `ValidatorType`.
    var validatorReadable: String {
        let all = array.map { "\($0)" }.joined(separator: ", ")
        return "in (\(all))"
    }

    /// Array to check against.
    let array: [T]

    /// Creates a new `InValidator`.
    init(_ array: [T]) {
        self.array = array
    }

    /// See `Validator`.
    func validate(_ item: T) throws {
        guard array.contains(item) else {
            throw BasicValidationError("is not \(validatorReadable)")
        }
    }
}
