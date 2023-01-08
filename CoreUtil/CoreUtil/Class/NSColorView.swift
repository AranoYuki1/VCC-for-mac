//
//  NSColorView.swift
//  CoreUtil
//
//  Created by yuki on 2021/10/05.
//  Copyright © 2021 yuki. All rights reserved.
//

import Cocoa

open class NSShapeView: NSLoadView {
    open var fillColor: NSColor? { didSet { setNeedsDisplay(bounds) } }
    
    open var borderWidth: CGFloat = 1 { didSet { setNeedsDisplay(bounds) } }
    open var borderColor: NSColor? { didSet { setNeedsDisplay(bounds) } }
    open var borderDashPatten: [CGFloat]? { didSet { setNeedsDisplay(bounds) } }
    
    open var windingRule: NSBezierPath.WindingRule = .evenOdd { didSet { setNeedsDisplay(bounds) } }
    open var borderCapStyle: NSBezierPath.LineCapStyle = .round { didSet { setNeedsDisplay(bounds) } }
    open var borderJoinStyle: NSBezierPath.LineJoinStyle = .miter { didSet { setNeedsDisplay(bounds) } }
    open var miterLimit: CGFloat = 10 { didSet { setNeedsDisplay(bounds) } }
    open var flatness: CGFloat = 0.6 { didSet { setNeedsDisplay(bounds) } }
    
    internal func drawBorder(_ path: NSBezierPath) {
        guard let borderColor = borderColor else { return }
        borderColor.setStroke()
        
        if let dashPatten = borderDashPatten {
            dashPatten.withUnsafeBufferPointer{
                path.setLineDash($0.baseAddress, count: dashPatten.count, phase: 0)
            }
        }
        
        path.windingRule = windingRule
        path.lineCapStyle = borderCapStyle
        path.lineJoinStyle = borderJoinStyle
        path.miterLimit = miterLimit
        path.flatness = flatness
        path.lineWidth = borderWidth
        path.stroke()
    }
    
    internal func drawFill(_ path: NSBezierPath) {
        guard let fillColor = fillColor else { return }
        fillColor.setFill()
        path.windingRule = windingRule
        path.flatness = flatness
        path.miterLimit = miterLimit
        path.fill()
    }
}

open class NSRectangleView: NSShapeView {
    open var cornerRadius: CGFloat = 0 { didSet { setNeedsDisplay(bounds) } }
    
    open override func draw(_ dirtyRect: NSRect) {
        let fillPath = NSBezierPath(roundedRect: bounds, xRadius: cornerRadius, yRadius: cornerRadius)
        drawFill(fillPath)
        
        let delta = self.borderWidth
        let borderPath = NSBezierPath(roundedRect: bounds.insetBy(dx: delta/2, dy: delta/2), xRadius: cornerRadius-delta, yRadius: cornerRadius-delta)
        drawBorder(borderPath)
    }
}

open class NSCapsule: NSShapeView {
    
    open override func draw(_ dirtyRect: NSRect) {
        let cornerRadius = frame.size.minElement/2
            
        let fillPath = NSBezierPath(roundedRect: bounds, xRadius: cornerRadius, yRadius: cornerRadius)
        drawFill(fillPath)
        
        let delta = self.borderWidth
        let borderPath = NSBezierPath(roundedRect: bounds.insetBy(dx: delta/2, dy: delta/2), xRadius: cornerRadius-delta, yRadius: cornerRadius-delta)
        drawBorder(borderPath)
    }
}

