//
//  Ex+Draw.swift
//  CoreUtil
//
//  Created by yuki on 2023/01/01.
//

import Cocoa

extension NSString {
    public func draw(centerY rect: CGRect, attributes: [NSAttributedString.Key : Any]? = nil) {
        let actualRect = self.boundingRect(with: rect.size, options: [.usesLineFragmentOrigin], attributes: attributes)
        let originY = rect.minY + (rect.height - actualRect.height) / 2
        let drawRect = CGRect(origin: [rect.minX, originY], size: actualRect.size)
        
        self.draw(with: drawRect, options: .usesLineFragmentOrigin, attributes: attributes)
    }
    public func drawRight(centerY rect: CGRect, attributes: [NSAttributedString.Key : Any]? = nil) {
        let actualRect = self.boundingRect(with: rect.size, options: [.usesLineFragmentOrigin], attributes: attributes)
        let originY = rect.minY + (rect.height - actualRect.height) / 2
        var drawRect = CGRect(origin: [0, originY], size: actualRect.size)
        drawRect.end.x = rect.end.x
        
        self.draw(with: drawRect, options: .usesLineFragmentOrigin, attributes: attributes)
    }
    
    public func draw(center rect: CGRect, attributes: [NSAttributedString.Key : Any]? = nil) {
        let actualRect = self.boundingRect(with: rect.size, options: [.usesLineFragmentOrigin], attributes: attributes)
        let origin = (rect.size - actualRect.size).convertToPoint() / 2
        let drawRect = CGRect(origin: rect.origin + origin, size: actualRect.size)
        
        self.draw(with: drawRect, options: .usesLineFragmentOrigin, attributes: attributes)
    }
}
