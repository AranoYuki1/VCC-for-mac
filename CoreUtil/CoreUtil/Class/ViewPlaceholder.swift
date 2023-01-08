//
//  ViewPlaceholder.swift
//  CoreUtil
//
//  Created by yuki on 2021/06/03.
//  Copyright © 2021 yuki. All rights reserved.
//

import Cocoa
import Combine

open class NSPlaceholderView<View: NSView>: NSLoadView {
    public var contentView: View? {
        didSet {
            oldValue?.removeFromSuperview()
            if let contentView = contentView {
                self.addSubview(contentView)
                contentView.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    contentView.rightAnchor.constraint(equalTo: self.rightAnchor),
                    contentView.leftAnchor.constraint(equalTo: self.leftAnchor),
                    contentView.topAnchor.constraint(equalTo: self.topAnchor),
                    contentView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
                ])
            }
        }
    }
}

final public class NSViewPlaceholder {
    public var view: NSView? {
        didSet {
            if let view = oldValue { self.removeOldView(view: view) }
            updateContent()
        }
    }
    
    public init() {}
    
    private var attacher: Attacher?
    
    private struct Attacher {
        let view: NSView
        let layout: (NSView) -> ()
    }
    
    func attach(_ view: NSView, _ layout: @escaping (NSView) -> ()) {
        self.attacher = .init(view: view, layout: layout)
        self.updateContent()
    }
    
    private func removeOldView(view: NSView) {
        view.removeFromSuperview()
        for constraint in view.constraints {
            view.removeConstraint(constraint)
        }
    }
    private func updateContent() {
        guard let view = view, let attacher = self.attacher else { return }
        attacher.view.addSubview(view)
        attacher.layout(view)
    }
    
}

extension NSView {
    public func addPlaceholder(_ placeholder: NSViewPlaceholder, _ layout: @escaping (NSView) -> ()) {
        placeholder.attach(self, layout)
    }
}
