# Getting Started

Add validation rules to a model and validate an instance.

## Overview

To validate a type, conform it to ``Validatable`` and implement
``Validatable/validations()``. Conforming to ``Reflectable`` (free for `Codable`
types) lets the library infer human-readable error paths from each property's `KeyPath`.

``Validatable`` inherits `Sendable`, so a `struct` whose properties are all `Sendable`
conforms as-is; a `class` needs `@unchecked Sendable`. See <doc:MigratingToSwift6>.

### Declaring validations

Build a ``Validations`` value and add a rule per property:

```swift
import Validation

struct User: Validatable, Reflectable, Codable {
    var name: String
    var age: Int
    var email: String?
    var preferedColors: [String]

    static func validations() throws -> Validations<User> {
        var validations = Validations(User.self)

        // name: at least 5 characters and alphanumeric
        try validations.add(\.name, .count(5...) && .alphanumeric)

        // age: 18 or older
        try validations.add(\.age, .range(18...))

        // email: nil, or a valid email address
        try validations.add(\.email, .nil || .email)

        // preferedColors: not empty
        try validations.add(\.preferedColors, !.empty)

        return validations
    }
}
```

### Running validation

Call ``Validatable/validate()`` on an instance. It throws a ``ValidationError`` if any
rule fails:

```swift
do {
    try user.validate()
} catch let error as any ValidationError {
    print(error.reason)
}
```

### Validating values directly

A ``Validator`` can validate a single value without a model:

```swift
try Validator<String>.email.validate("user@example.com")
try Validator<Int>.range(-5...5).validate(4)
```

### Explicit error paths

For models that are not `Reflectable`, supply the readable path used in error messages:

```swift
var validations = Validations(User.self)
validations.add(\.name, at: ["name"], .count(5...) && .alphanumeric)
```
</content>
