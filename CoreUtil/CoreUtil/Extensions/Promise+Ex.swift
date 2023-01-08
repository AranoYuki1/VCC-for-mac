//
//  Promise+Ex.swift
//  CoreUtil
//
//  Created by yuki on 2022/12/28.
//

import Promise

extension Promise {
    public static func sleep(for duration: TimeInterval) -> Promise<Void, Never> where Output == Void, Failure == Never {
        let promise = Promise<Void, Never>()
        Timer.scheduledTimer(withTimeInterval: duration, repeats: false, block: { _ in
            promise.fullfill(())
        })
        return promise
    }
}

