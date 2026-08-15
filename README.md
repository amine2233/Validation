# Validation

[![CI](https://github.com/amine2233/Validation/actions/workflows/ci.yml/badge.svg)](https://github.com/amine2233/Validation/actions/workflows/ci.yml)

A lightweight, declarative validation library for Swift models, inspired by and
largely ported from [Vapor's Validation](https://github.com/vapor/validation).

Describe how a model's properties should be validated using composable, type-safe
validators, then call `validate()`. All failures are collected and reported with
human-readable, fully-qualified key paths.

## Features

- ✅ Declarative, per-property validation via `KeyPath`
- 🧩 Composable validators with `&&`, `||` and `!` operators
- 🔍 Automatic error-path reflection for `Codable` / `Reflectable` models
- 📦 Collects **all** validation errors in one pass (not fail-fast)
- 🔒 Swift 6 language mode — every public type is `Sendable`
- 🐧 Builds and tests on both macOS and Linux

## Requirements

- Swift 6.0+ toolchain (the package builds in Swift 6 language mode)
- Apple platforms or Linux

## Installation

### Swift Package Manager

Add the package to your `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/amine2233/Validation.git", from: "0.0.2")
]
```

Then add `Validation` to your target's dependencies:

```swift
.target(name: "MyApp", dependencies: ["Validation"])
```

## Usage

Conform your model to `Validatable` (and `Reflectable` to get automatic error
paths), then declare its validations:

```swift
import Validation

struct User: Validatable, Reflectable, Codable {
    var name: String
    var age: Int
    var email: String?
    var luckyNumber: Int?
    var profilePictureURL: String?
    var preferedColors: [String]

    static func validations() throws -> Validations<User> {
        var validations = Validations(User.self)

        // name: at least 5 characters and alphanumeric
        try validations.add(\.name, .count(5...) && .alphanumeric)

        // age: 18 or older
        try validations.add(\.age, .range(18...))

        // email: nil, or a valid email address
        try validations.add(\.email, .nil || .email)

        // luckyNumber: nil, or one of 5 / 7
        try validations.add(\.luckyNumber, .nil || .in(5, 7))

        // profilePictureURL: nil, or a valid URL
        try validations.add(\.profilePictureURL, .url || .nil)

        // preferedColors: not empty
        try validations.add(\.preferedColors, !.empty)

        return validations
    }
}
```

Validate an instance:

```swift
let user = User(/* ... */)

do {
    try user.validate()
} catch let error as any ValidationError {
    print(error.reason) // e.g. "name is less than required minimum of 5 characters"
}
```

Individual validators can also be used directly:

```swift
try Validator<String>.email.validate("user@example.com")
try Validator<Int>.range(-5...5).validate(4)
```

## Swift 6 & Sendable

`Validatable`, `ValidatorType` and `ValidationError` now inherit `Sendable`, and
`Validator` stores an `@Sendable` closure. Two consequences when upgrading:

- A model conforming to `Validatable` must be `Sendable`. A `struct` of `Sendable`
  properties qualifies as-is; a `class` needs `@unchecked Sendable` (or, better, becomes
  a `struct`).
- Validated property types must be `Sendable` — `add(_:_:)` is now
  `add<T: Sendable>(_:_:)` — and custom closures passed to `add(_:at:_:custom:)` are
  `@Sendable`, so they cannot capture mutable shared state.

```swift
final class User: Validatable, Reflectable, Codable, @unchecked Sendable { /* ... */ }
```

Also removed in the Swift 6 release: the CocoaPods podspec, `Tests/LinuxMain.swift` and
`XCTestManifests.swift` — tests use [Swift Testing](https://github.com/swiftlang/swift-testing),
which discovers tests on Linux without generated manifests.

The full list of breaking changes is in the
[Migrating to Swift 6](Sources/Validation/Validation.docc/MigratingToSwift6.md) article.

## Example: forms, field by field and all at once

The same `Validator` values drive a live UI form and a server-side payload check —
only the reporting strategy differs.

**Front end — first failure per field.** A text field has room for one message, so stop
at the first unmet rule:

```swift
struct FieldRule<Value: Sendable>: Sendable {
    let validator: Validator<Value>
    let message: String
}

func evaluate<Value>(_ value: Value, rules: [FieldRule<Value>]) -> String? {
    for rule in rules {
        do { try rule.validator.validate(value) } catch { return rule.message }
    }
    return nil
}

evaluate(password, rules: [
    FieldRule(validator: .count(8...), message: "At least 8 characters."),
    FieldRule(validator: .alphanumeric, message: "Letters and digits only."),
])
```

**Back end — every failure in one shot.** `Validations.run(on:)` never stops at the
first failure, so `validate()` reports the whole list in a single `reason`:

```swift
struct SignUpRequest: Validatable, Reflectable, Codable {
    var email: String
    var password: String
    var age: Int

    static func validations() throws -> Validations<SignUpRequest> {
        var validations = Validations(SignUpRequest.self)
        try validations.add(\.email, .email)
        try validations.add(\.password, .count(8...) && .alphanumeric)
        try validations.add(\.age, .range(18...))
        return validations
    }
}

do {
    try request.validate()
} catch let error as any ValidationError {
    // "email is not a valid email address, age is less than 18"
    print(error.reason)
}
```

The complete version — a `FieldValidation` state enum, a `FormValidatable` protocol
that derives `isValid` and per-field errors, and rules shared between both layers — is
in the [Validating Forms](Sources/Validation/Validation.docc/ValidatingForms.md) article.

## Built-in validators

| Validator | Applies to | Description |
|-----------|------------|-------------|
| `.email` | `String` | Valid email address |
| `.url` | `String` | Valid URL |
| `.ascii` | `String` | ASCII characters only |
| `.alphanumeric` | `String` | Alphanumeric characters only |
| `.characterSet(_:)` | `String` | Characters within the given `CharacterSet` |
| `.count(_:)` | `Collection` | Element/character count within a range |
| `.range(_:)` | `Comparable` | Value within a range |
| `.empty` | `Collection` | Value is empty |
| `.in(_:)` | `Equatable` | Value is one of the supplied values |
| `.nil` | `Optional` | Value is `nil` |

### Combining validators

- `&&` — both validators must pass (`AndValidator`)
- `||` — at least one validator must pass (`OrValidator`)
- `!`  — inverts a validator (`NotValidator`)
- `.nil || .someValidator` — ignore validation when the value is `nil` (`NilIgnoringValidator`)
- `CharacterSet + CharacterSet` — union of character sets

```swift
.count(5...) && .alphanumeric          // 5+ chars AND alphanumeric
.nil || .email                          // nil OR valid email
.characterSet(.alphanumerics + .whitespaces)
```

## Documentation

API documentation is provided as a [DocC](https://www.swift.org/documentation/docc/)
catalog located at `Sources/Validation/Validation.docc`, and published to
[GitHub Pages](https://amine2233.github.io/Validation/documentation/validation) on every
push to `main`. Build it locally with:

```bash
mise run build_documentations macOS --serve   # or: Product ▸ Build Documentation in Xcode
```

## Development

```bash
swift build -v                                        # Build
mise run test                                         # Run all tests
swift test --filter "ValidationTests/email"           # Run a single test
mise run lint                                         # Format + code + documentation checks
mise run format                                       # Format the code
```

> **Note:** Tests use [Swift Testing](https://github.com/swiftlang/swift-testing)
> (`@Test`, `#expect`). Test discovery works on Linux without generated manifests, so no
> `--generate-linuxmain` step is needed anymore.

## License

`Validation` is available under the MIT license.
