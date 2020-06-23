//
//  AtomicProperty.swift
//  Validation
//
//  Created by Amine Bensalah on 02/05/2020.
//

import Foundation

struct AtomicProperty<T> {
    private var storageValue: T?
    private let lock: NSLock

    init(lock: NSLock = NSLock()) {
        self.lock = lock
    }

    var currentValue: T? {
        get {
            _ = lock.lock()
            let value = storageValue
            lock.unlock()
            return value
        }
        set {
            _ = lock.lock()
            storageValue = newValue
            lock.unlock()
        }
    }
}
