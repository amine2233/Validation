//
//  Lock.swift
//  Validation
//
//  Created by Amine Bensalah on 02/05/2020.
//

import Foundation
#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

internal class Lock {
    fileprivate var mutex = pthread_mutex_t()
    fileprivate var attributes = pthread_mutexattr_t()

    init() {
        pthread_mutexattr_init(&attributes)
        pthread_mutexattr_settype(&attributes, PTHREAD_MUTEX_RECURSIVE)
        pthread_mutex_init(&mutex, &attributes)
    }

    deinit {
        pthread_mutex_destroy(&mutex)
    }

    func lock() -> Int32 {
        return pthread_mutex_lock(&mutex)
    }

    @discardableResult
    func unlock() -> Int32 {
        return pthread_mutex_unlock(&mutex)
    }

    func lock(_ closure: () -> Void) {
        let status = lock()
        assert(status == 0, "pthread_mutex_lock: \(String(describing: strerror(status)))")
        defer { unlock() }
        closure()
    }
}
