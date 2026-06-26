# Validation

[![Swift](https://github.com/amine2233/Validation/actions/workflows/swift.yml/badge.svg)](https://github.com/amine2233/Validation/actions/workflows/swift.yml)

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
- 🐧 Builds and tests on both macOS and Linux

## Requirements

- Swift 5.2+
- iOS 13+ / macOS 10.15+ / tvOS 13+ / watchOS 6+ (when used via CocoaPods)

## Installation

### Swift Package Manager

Add the package to your `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/amine2233/Validation.git", from: "0.1.0")
]
```

Then add `Validation` to your target's dependencies:

```swift
.target(name: "MyApp", dependencies: ["Validation"])
```

### CocoaPods

```ruby
pod 'Validation'
```

## Usage

Conform your model to `Validatable` (and `Reflectable` to get automatic error
paths), then declare its validations:

```swift
import Validation

final class User: Validatable, Reflectable, Codable {
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
} catch let error as ValidationError {
    print(error.reason) // e.g. "name is less than required minimum of 5 characters"
}
```

Individual validators can also be used directly:

```swift
try Validator<String>.email.validate("user@example.com")
try Validator<Int>.range(-5...5).validate(4)
```

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
catalog located at `Sources/Validation/Validation.docc`. Build it with:

```bash
swift package generate-documentation        # requires the Swift-DocC plugin
# or, in Xcode: Product ▸ Build Documentation
```

## Development

```bash
swift build -v                                   # Build
swift test -v                                    # Run all tests
swift test --filter ValidationTests/testEmail    # Run a single test
swift test --generate-linuxmain                  # Regenerate Linux test manifests
```

> **Note:** Tests use XCTest. Because the package supports Linux, regenerate the test
> manifests with `swift test --generate-linuxmain` whenever you add or remove a test,
> otherwise the new test will not run on Linux CI.

## License

`Validation` is available under the MIT license.
</content>
