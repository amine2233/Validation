//
//  AndValidator.swift
//  Validation
//
//  Created by Amine Bensalah on 02/05/2020.
//

import Foundation

/// Combines two `Validator`s using AND logic, succeeding if both `Validator`s succeed without error.
///
///     try validations.add(\.name, .range(5...) && .alphanumeric)
///
public func &&<T> (lhs: Validator<T>, rhs: Validator<T>) -> Validator<T> {
    return AndValidator(lhs, rhs).validator()
}

fileprivate struct AndValidator<T>: ValidatorType {
    /// See `ValodatorType`.
    public var validatorReadable: String {
        return ""
    }

    /// left validator
    let lhs: Validator<T>

    /// right validator
    let rhs: Validator<T>

    /// create a new and validator
    init(_ lhs: Validator<T>, _ rhs: Validator<T>) {
        self.lhs = lhs
        self.rhs = rhs
    }

    /// See `ValidatorType`.
    func validate(_ data: T) throws {
        var left: ValidationError?
        do {
            try lhs.validate(data)
        } catch let leftError as ValidationError {
            left = leftError
        }

        var right: ValidationError?
        do {
            try rhs.validate(data)
        } catch let rightError as ValidationError {
            right = rightError
        }

        if left != nil || right != nil {
            throw AndValidatorError(left, right)
        }
    }
}

/// Error thrown if and validation fails
fileprivate struct AndValidatorError: ValidationError {
    /// error thrown by left validator
    let left: ValidationError?

    /// error thrown by right validator
    let right: ValidationError?

    /// See ValidationError.reason
    var reason: String {
        if let left = left, let right = right {
            var mutableLeft = left, mutableRight = right
            mutableLeft.path = path + left.path
            mutableRight.path = path + right.path
            return "\(mutableLeft.reason) and \(mutableRight.reason)"
        } else if let left = left {
            var mutableLeft = left
            mutableLeft.path = path + left.path
            return mutableLeft.reason
        } else if let right = right {
            var mutableRight = right
            mutableRight.path = path + right.path
            return mutableRight.reason
        } else {
            return ""
        }
    }

    /// See ValidationError.keyPath
    var path: [String]

    /// Creates a new or validator error
    init(_ left: ValidationError?, _ right: ValidationError?) {
        self.left = left
        self.right = right
        self.path = []
    }
}
