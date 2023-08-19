//
//  ACSelectionHeaderView.swift
//  AxComponents
//
//  Created by yuki on 2021/12/02.
//  Copyright © 2021 yuki. All rights reserved.
//

import Combine
import Cocoa
import CoreUtil

final class EnumSelectionBar<Item: TextItem>: SelectionBar {
    public var items = [Item]()
    
    var itemPublisher: AnyPublisher<Item, Never> {
        self.selectedIndexPublisher.map{[unowned self] in self.items[$0] }.eraseToAnyPublisher()
    }
    var selectedItem: Item? {
        didSet { self.selectedItemIndex = selectedItem.flatMap{ self.items.firstIndex(of: $0) } }
    }
    
    func addItem(_ item: Item) {
        self.items.append(item)
        self.addItem(item.title)
    }
    
    func addAllItems() {
        Item.allCases.forEach{ self.addItem($0) }
    }
}

final class NSHorizontallyScrollableScrollView: NSScrollView {
    override func scrollWheel(with event: NSEvent) {
        guard event.modifierFlags.contains(.command) || event.modifierFlags.contains(.shift) else {
            super.scrollWheel(with: event)
            return
        }

        if let cgEvent: CGEvent = event.cgEvent?.copy() {
            cgEvent.setDoubleValueField(.scrollWheelEventDeltaAxis1, value: Double(event.scrollingDeltaX))
            cgEvent.setDoubleValueField(.scrollWheelEventDeltaAxis2, value: Double(event.scrollingDeltaY))

            if let nsEvent = NSEvent(cgEvent: cgEvent) {
                super.scrollWheel(with: nsEvent)
            }
        }
    }
}

class SelectionBar: NSLoadView {
    var edgeInsets: NSEdgeInsets { get { stackView.edgeInsets } set { stackView.edgeInsets = newValue } }
    var spacing: CGFloat { get { stackView.spacing } set { stackView.spacing = newValue } }
    
    private let stackView = NSStackView()
    private let scrollView = NSHorizontallyScrollableScrollView()
    
    struct Item {
        let title: String
        let rightAction: ((NSView) -> ())?
    }
    
    var selectedItemIndex: Int? {
        didSet {
            if let selectedItemIndex = self.selectedItemIndex {
                self.selectedItem = itemViews.at(selectedItemIndex)
            } else {
                self.selectedItem = nil
            }
        }
    }
    
    var selectedIndexPublisher: AnyPublisher<Int, Never> {
        selectedItemSubject
            .compactMap{[unowned self] item in self.itemViews.firstIndex(where: { $0 === item }) }
            .eraseToAnyPublisher()
    }
    
    private let selectedItemSubject = PassthroughSubject<SelectionItemView, Never>()
    private var itemViews = [SelectionItemView]()
    private var selectedItem: SelectionItemView? {
        didSet {
            oldValue?.isSelected = false
            selectedItem?.isSelected = true
        }
    }
    
    func removeAllItems() {
        self.itemViews.forEach{ $0.removeFromSuperview() }
        self.itemViews = []
    }
    
    func addItem(_ title: String) {
        self.addItem(Item(title: title, rightAction: nil))
    }

    func addItem(_ item: Item) {
        let itemView = SelectionItemView(title: item.title)
        itemView.rightAction = item.rightAction
        self.itemViews.append(itemView)
        self.stackView.addArrangedSubview(itemView)
        
        itemView.selectPublisher
            .sink{[unowned itemView] in self.selectedItemSubject.send(itemView) }.store(in: &itemView.objectBag)
    }
    
    override var intrinsicContentSize: NSSize { _intrinsicContentSize }
    
    private var _intrinsicContentSize = NSSize.zero
    
    override func onAwake() {
        self.snp.makeConstraints{ make in
            make.height.equalTo(24)
        }
        self.addSubview(scrollView)
        self.scrollView.drawsBackground = false
        self.scrollView.snp.makeConstraints{ make in
            make.edges.equalToSuperview()
        }
        
        self.scrollView.verticalScrollElasticity = .none
        self.scrollView.documentView = stackView
        
        self.stackView.spacing = 4
        self.stackView.snp.makeConstraints{ make in
            make.height.equalTo(24)
            make.top.left.bottom.equalToSuperview()
        }
        
        self.stackView.publisher(for: \.frame)
            .sink{[unowned self] frame in
                self._intrinsicContentSize = frame.size
                self.invalidateIntrinsicContentSize()
            }
            .store(in: &objectBag)
    }
}

final private class SelectionItemView: NSLoadView {
    let titleLabel = NSTextField(labelWithString: "")
    var isSelected = false { didSet { needsDisplay = true } }
    var isHighlighted = false { didSet { needsDisplay = true } }
    var rightAction: ((NSView) -> ())? = nil
    
    let selectPublisher = PassthroughSubject<Void, Never>()
    
    convenience init(title: String) {
        self.init()
        self.titleLabel.stringValue = title
    }
    
    override func rightMouseDown(with event: NSEvent) {
        rightAction?(self)
    }
    
    override func mouseDown(with event: NSEvent) {
        self.isHighlighted = true
    }
    override func mouseDragged(with event: NSEvent) {
        self.isHighlighted = bounds.contains(event.location(in: self))
    }
    override func mouseUp(with event: NSEvent) {
        self.isHighlighted = false
        
        if bounds.contains(event.location(in: self)) {
            self.selectPublisher.send()
        }
    }
    
    override func updateLayer() {
        if isSelected {
            self.titleLabel.textColor = .white
            if isHighlighted {
                self.layer?.backgroundColor = NSColor.controlAccentColor.highlight(withLevel: 0.1)!.cgColor
            } else {
                self.layer?.backgroundColor = NSColor.controlAccentColor.cgColor
            }
        } else {
            self.titleLabel.textColor = NSColor.textColor.withAlphaComponent(0.3)
            if isHighlighted {
                self.layer?.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.5).shadow(withLevel: 0.1)!.cgColor
            } else {
                self.layer?.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.5).cgColor
            }
        }
    }
    
    override func onAwake() {
        self.wantsLayer = true
        self.layer?.cornerRadius = R.size.corner
        self.addSubview(titleLabel)
        self.titleLabel.font = .systemFont(ofSize: 11)
        self.titleLabel.snp.makeConstraints{ make in
            make.right.left.equalToSuperview().inset(10)
            make.top.bottom.equalToSuperview().inset(3)
        }
    }
}
 


