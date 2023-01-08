//
//  R.swift
//  DevToys
//
//  Created by yuki on 2022/01/29.
//

import Cocoa

extension _R {
    var size: Size { Size() }
    
    struct Size {
        let corner: CGFloat = 5
        let controlHeight: CGFloat = 26
    }
    
    var fontSize: FontSize { FontSize() }

    struct FontSize {
        let sidebarTitle: CGFloat = 12
        let controlTitle: CGFloat = 12
        let control: CGFloat = 10.5
    }
}

extension _R.color {
    func controlBackgroundColor() -> NSColor { NSColor.textColor.withAlphaComponent(0.08) }
    func controlHighlightedBackgroundColor() -> NSColor { NSColor.textColor.withAlphaComponent(0.15) }
    func transparentBackground() -> NSColor { NSColor(patternImage: R.image.transparentBackground()) }
}

extension Bundle {
    static let current = Bundle(for: { class __ {}; return  __.self }())
}
