//
//  +Functions.swift
//  CoreUtil
//
//  Created by yuki on 2020/10/01.
//  Copyright © 2020 yuki. All rights reserved.
//

precedencegroup PipePrecedence {
    higherThan: NilCoalescingPrecedence
    associativity: left
}

infix operator =>: PipePrecedence

public func => <T>(lhs: T, rhs: (T) throws -> Void) rethrows -> T {
    try rhs(lhs)
    return lhs
}
