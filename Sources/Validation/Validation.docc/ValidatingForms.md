# Validating Forms

Two ways to consume the same validators: field by field for a UI, or all at once for
a server.

## Overview

A ``Validator`` is a plain value, so the same rule can drive a live SwiftUI form *and*
a server-side payload check. Declare the rules once and pick the strategy that fits
the caller:

- **Per field, first failure wins** — a text field has room for one message, and the
  first unmet rule is the one the user has to fix.
- **Whole model, every failure at once** — an API response should list everything that
  is wrong in a single round trip. This is what ``Validations/run(on:)`` already does.

### Declaring the rules once

```swift
import Validation

enum SignUpRules {
    static let email = Validator<String>.email
    static let password = Validator<String>.count(8...)
    static let age = Validator<Int>.range(18...)
}
```

## Front end: one field at a time

Each field reports its own state. `.none` is not "valid" — it means the field has
nothing to say yet (untouched, or not applicable for the current selection, like a
Wi-Fi password on an open network). The UI renders no icon for it, where `.valid`
renders a checkmark.

```swift
import Foundation
import Validation

/// The state of one form field.
public enum FieldValidation: Hashable, Sendable {
    case none
    case valid
    case invalid(message: String)

    public var isValid: Bool {
        if case .invalid = self { false } else { true }
    }

    public var message: String? {
        if case let .invalid(message) = self { message } else { nil }
    }
}
```

One rule pairs a ``Validator`` with the message shown when it fails. Since Swift 6 both
``Validator`` and the rule are `Sendable`, so rules can be stored in state or passed
across concurrency domains — see <doc:MigratingToSwift6>.

```swift
/// One rule: a `Validator` plus the message shown when it fails.
public struct FieldRule<Value: Sendable>: Sendable {
    let validator: Validator<Value>
    let message: String

    /// Creates a rule.
    ///
    /// - Parameters:
    ///   - validator: The check to run.
    ///   - message: What the field says when the check fails.
    public init(_ validator: Validator<Value>, message: String) {
        self.validator = validator
        self.message = message
    }
}

/// Runs ``FieldRule`` sets against a value.
public enum FieldValidator {
    /// Runs rules in order and reports the first failure.
    ///
    /// First-failure rather than collect-all: the first unmet rule is the one the user
    /// has to fix before any later rule even becomes meaningful.
    public static func evaluate<Value>(
        _ value: Value,
        rules: [FieldRule<Value>]
    ) -> FieldValidation {
        for rule in rules {
            do {
                try rule.validator.validate(value)
            } catch {
                return .invalid(message: rule.message)
            }
        }
        return .valid
    }
}
```

A payload declares its fields and how each one is judged; `isValid` and `validations`
come free:

```swift
/// The pattern every form payload follows.
public protocol FormValidatable {
    /// The fields the form presents, one case each.
    associatedtype Field: Hashable & CaseIterable & Sendable

    /// The verdict for one field.
    func validation(for field: Field) -> FieldValidation
}

extension FormValidatable {
    /// Whether no field is reporting an error.
    ///
    /// Note this is `true` for an untouched form — a required-but-empty field reports
    /// `.none`, not `.invalid`, so the user is not told off before typing. Callers that
    /// need "complete enough to save" check emptiness too.
    public var isValid: Bool {
        Field.allCases.allSatisfy { validation(for: $0).isValid }
    }

    /// The verdict for every field.
    public var validations: [Field: FieldValidation] {
        Field.allCases.reduce(into: [:]) { result, field in
            result[field] = validation(for: field)
        }
    }
}
```

Conforming a payload wires the shared rules to its fields:

```swift
struct SignUpForm: FormValidatable {
    enum Field: Hashable, CaseIterable, Sendable {
        case email, password
    }

    var email = ""
    var password = ""

    func validation(for field: Field) -> FieldValidation {
        switch field {
        case .email:
            guard !email.isEmpty else { return .none }
            return FieldValidator.evaluate(email, rules: [
                FieldRule(SignUpRules.email, message: "Enter a valid email address."),
            ])
        case .password:
            guard !password.isEmpty else { return .none }
            return FieldValidator.evaluate(password, rules: [
                FieldRule(SignUpRules.password, message: "At least 8 characters."),
                FieldRule(.alphanumeric, message: "Letters and digits only."),
            ])
        }
    }
}
```

The Done button gates on `form.isValid`, and each field renders
`form.validation(for: .email).message`.

## Back end: everything in one shot

A server does not want the first failure — it wants the whole list, so the client can
fix every problem at once. Conform the payload to ``Validatable`` and call
``Validatable/validate()``: ``Validations`` runs **all** rules and throws a single
combined ``ValidationError``.

```swift
struct SignUpRequest: Validatable, Reflectable, Codable {
    var email: String
    var password: String
    var age: Int

    static func validations() throws -> Validations<SignUpRequest> {
        var validations = Validations(SignUpRequest.self)
        try validations.add(\.email, SignUpRules.email)
        try validations.add(\.password, SignUpRules.password && .alphanumeric)
        try validations.add(\.age, SignUpRules.age)
        return validations
    }
}

do {
    try request.validate()
} catch let error as any ValidationError {
    // "email is not a valid email address, age is less than 18"
    return Response(status: .badRequest, message: error.reason)
}
```

`error.reason` joins every failure, each prefixed with its reflected key path — nested
models report dotted paths such as `pet.name is less than required minimum of 5
characters`.

### Per-field results without throwing

When the response body needs one entry per field rather than a single string, run the
rules per field and keep the failures:

```swift
extension FormValidatable {
    /// The message for every field that is failing.
    public var errors: [Field: String] {
        validations.compactMapValues(\.message)
    }
}
```

`SignUpForm().errors` is then `[:]` when the form is clean, and
`[.password: "At least 8 characters."]` when it is not — ready to encode as JSON.

## See Also

- <doc:GettingStarted>
- <doc:ComposingValidators>
- <doc:MigratingToSwift6>
