//
//  NSObject+Combine.swift
//  CoreUtil
//
//  Created by yuki on 2020/05/22.
//  Copyright © 2020 yuki. All rights reserved.
//

import Foundation
import Combine

private var bagKey: UInt8 = 0

public typealias Bag = Set<AnyCancellable>

extension NSObject {
    public var objectBag: Bag {
        get { bagContainer.value } set { bagContainer.value = newValue }
    }
    
    private class BagContainer {
        var value = Bag()
    }
    
    private var bagContainer: BagContainer {
        if let container = objc_getAssociatedObject(self, &bagKey) as? BagContainer { return container }
        let container = BagContainer()
        objc_setAssociatedObject(self, &bagKey, container, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return container
    }
}
