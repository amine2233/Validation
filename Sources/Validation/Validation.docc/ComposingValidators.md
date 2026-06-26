# Composing Validators

Combine built-in validators into richer rules using operators.

## Overview

Every rule is a ``Validator`` value, so validators compose with logical operators to
express complex requirements concisely.

### Built-in validators

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

### Operators

- `&&` — both validators must pass.
- `||` — at least one validator must pass.
- `!` — inverts a validator.
- `CharacterSet + CharacterSet` — union of two character sets.

```swift
.count(5...) && .alphanumeric            // 5+ characters AND alphanumeric
.nil || .email                            // nil OR a valid email
!.empty                                   // must not be empty
.characterSet(.alphanumerics + .whitespaces)
```

### Optional values

Combining a `nil` check with another validator on an optional property lets the rule
skip validation when the value is absent:

```swift
try validations.add(\.email, .nil || .email)        // valid email, or nil
try validations.add(\.luckyNumber, .nil || .in(5, 7))
try validations.add(\.profilePictureURL, .url || .nil)
```

### Combining ranges and counts

`.range(_:)` and `.count(_:)` accept the full family of Swift range types — closed,
partial-through, partial-from, and half-open:

```swift
.range(18...)        // 18 or older
.range(-5...5)       // between -5 and 5
.count(5...)         // at least 5
.count(...140)       // at most 140
```
</content>
