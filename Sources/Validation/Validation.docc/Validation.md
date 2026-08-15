# ``Validation``

A lightweight, declarative validation library for Swift models.

## Overview

`Validation` lets you describe how a model's properties should be validated using
composable, type-safe validators, then validate an instance with a single call. It is
inspired by and largely ported from [Vapor's Validation](https://github.com/vapor/validation).

The package builds in Swift 6 language mode: every public type is `Sendable`, so
validators are safe to store and share across concurrency domains. Coming from an
earlier version? See <doc:MigratingToSwift6>.

Conform a model to ``Validatable`` (and optionally ``Reflectable`` to get automatic
error paths), declare its rules, and call ``Validatable/validate()``:

```swift
import Validation

struct User: Validatable, Reflectable, Codable {
    var name: String
    var age: Int
    var email: String?

    static func validations() throws -> Validations<User> {
        var validations = Validations(User.self)
        try validations.add(\.name, .count(5...) && .alphanumeric)
        try validations.add(\.age, .range(18...))
        try validations.add(\.email, .nil || .email)
        return validations
    }
}

try user.validate()
```

When validation fails, a ``ValidationError`` is thrown describing every failure with a
fully-qualified key path. ``Validations`` collects **all** failures in a single pass
rather than stopping at the first one.

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:ComposingValidators>
- <doc:ValidatingForms>
- <doc:MigratingToSwift6>
- ``Validatable``
- ``Validations``
- ``Validator``
- ``ValidatorType``

### Errors

- ``ValidationError``
- ``BasicValidationError``

### Reflection

- ``Reflectable``
- ``AnyReflectable``
- ``ReflectedProperty``
</content>
