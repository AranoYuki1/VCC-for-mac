//
//  UI+Debug.swift
//  CoreUtil
//
//  Created by yuki on 2022/12/21.
//

import AppKit

extension NSViewController {
    final private class __NSColorViewController: NSViewController {
        let contentView = NSRectangleView()
        override func loadView() { self.view = contentView }
    }
    
    public static func __color(_ color: NSColor) -> NSViewController {
        __NSColorViewController() => { (vc: __NSColorViewController) in
            vc.contentView.fillColor = color
        }
    }
}
