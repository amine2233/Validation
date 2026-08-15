# Migrating to Swift 6

What changed when the package moved to Swift 6 language mode, and how to update
your code.

## Overview

The package now builds with `swift-tools-version:6.0` and `swiftLanguageModes: [.v6]`,
so every public type takes part in strict concurrency checking. Validators are values
that get stored, passed between tasks and captured in closures, so the whole API is
now `Sendable`.

Nothing about how you *write* rules changed — `.count(5...) && .alphanumeric` is still
the same expression. What changed is which types are allowed to flow through the API.

### Breaking changes

| Symbol | Before | Now |
|--------|--------|-----|
| ``Validator`` | plain struct | `Sendable`, its closure is `@Sendable` |
| ``ValidatorType`` | plain protocol | inherits `Sendable` |
| ``Validatable`` | plain protocol | inherits `Sendable` |
| ``ValidationError`` | `Error` | `Error & Sendable` |
| ``Validations`` | `Validations<M: Validatable>` | `Validations<M: Sendable & Validatable>`, itself `Sendable` |
| `Validations.add(_:at:_:)` | `<T>` | `<T: Sendable>` |
| `Validations.add(_:at:_:custom:)` | `(T) throws -> Void` | `@Sendable (T) throws -> Void` |
| ``ReflectedProperty`` | plain struct | `Sendable` |

Also removed: the CocoaPods podspec, `Tests/LinuxMain.swift` and
`XCTestManifests.swift`. Tests now use [Swift Testing](https://github.com/swiftlang/swift-testing),
which discovers tests on Linux without generated manifests.

### Making a model conform

A `struct` whose stored properties are all `Sendable` satisfies the new requirement by
simply declaring ``Validatable`` — no extra work:

```swift
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
```

A mutable `class` can never be implicitly `Sendable`. Either move the model to a
`struct` — the recommended fix — or opt out explicitly, which makes thread safety your
responsibility:

```swift
final class User: Validatable, Reflectable, Codable, @unchecked Sendable {
    // ...
}
```

### Custom validators

``ValidatorType`` now inherits `Sendable`, so a custom validator may only store
`Sendable` state. Value-typed validators are already fine:

```swift
struct FrenchPostalCodeValidator: ValidatorType {
    var validatorReadable: String { "a valid French postal code" }

    func validate(_ data: String) throws {
        guard data.count == 5, data.allSatisfy(\.isNumber) else {
            throw BasicValidationError("is not a valid French postal code")
        }
    }
}

extension Validator where T == String {
    static var frenchPostalCode: Validator<String> {
        FrenchPostalCodeValidator().validator()
    }
}
```

Closures passed to `add(_:at:_:custom:)` are now `@Sendable`, so they cannot capture
mutable shared state:

```swift
try validations.add(\.name, "is vapor") { name in
    guard name == "vapor" else { throw BasicValidationError("is not vapor") }
}
```

### Catching errors

``ValidationError`` is a protocol, so catch it as an existential:

```swift
do {
    try user.validate()
} catch let error as any ValidationError {
    print(error.reason)
}
```

## See Also

- <doc:GettingStarted>
- <doc:ValidatingForms>
</invoke>
