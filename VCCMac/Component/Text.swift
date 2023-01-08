//
//  Text.swift
//  VCCMac
//
//  Created by yuki on 2022/12/26.
//

import CoreUtil

final public class H1Title: NSLoadView {
    
    public var text: String {
        get { label.stringValue } set { label.stringValue = newValue }
    }
    public var color: NSColor {
        get { label.textColor ?? .textColor } set { label.textColor = newValue }
    }
    public var isSelectable: Bool {
        get { label.isSelectable } set { label.isSelectable = newValue }
    }
    public var font: NSFont? {
        get { label.font } set { label.font = newValue }
    }
    
    private let label = NSTextField(labelWithString: "H1 Title")
    private let accessoryStackView = NSStackView() => {
        $0.orientation = .horizontal
    }
    
    public func addAccessoryView(_ view: NSView) {
        self.accessoryStackView.addArrangedSubview(view)
    }
    
    public convenience init(text: String) {
        self.init()
        self.text = text
    }
    
    public override func onAwake() {
        self.snp.makeConstraints{ make in
            make.height.equalTo(36)
        }
        
        self.addSubview(label)
        self.label.textColor = .textColor
        self.label.font = .systemFont(ofSize: 24, weight: .bold)
        self.label.snp.makeConstraints{ make in
            make.left.right.equalToSuperview()
            make.centerY.equalToSuperview().offset(-4)
        }
        
        self.addSubview(accessoryStackView)
        self.accessoryStackView.snp.makeConstraints{ make in
            make.right.top.bottom.equalToSuperview()
        }
    }
}

final public class H2Title: NSLoadView {
    
    public var text: String {
        get { label.stringValue } set { label.stringValue = newValue }
    }
    public var color: NSColor {
        get { label.textColor ?? .textColor } set { label.textColor = newValue }
    }
    public var isSelectable: Bool {
        get { label.isSelectable } set { label.isSelectable = newValue }
    }
    
    private let label = NSTextField(labelWithString: "H2 Title")
    
    public convenience init(text: String) {
        self.init()
        self.text = text
    }
    
    public override func onAwake() {
        self.snp.makeConstraints{ make in
            make.height.equalTo(32)
        }
        
        self.addSubview(label)
        self.label.textColor = .textColor
        self.label.font = .systemFont(ofSize: 20, weight: .bold)
        self.label.snp.makeConstraints{ make in
            make.left.right.equalToSuperview()
            make.centerY.equalToSuperview().offset(-4)
        }
    }
}

final public class H3Title: NSLoadView {
    
    public var text: String {
        get { label.stringValue } set { label.stringValue = newValue }
    }
    public var color: NSColor {
        get { label.textColor ?? .textColor } set { label.textColor = newValue }
    }
    public var isSelectable: Bool {
        get { label.isSelectable } set { label.isSelectable = newValue }
    }
    
    private let label = NSTextField(labelWithString: "H3 Title")
    
    public convenience init(text: String) {
        self.init()
        self.text = text
    }
    
    public override func onAwake() {
        self.snp.makeConstraints{ make in
            make.height.equalTo(30)
        }
        
        self.addSubview(label)
        self.label.textColor = .textColor
        self.label.font = .systemFont(ofSize: 18, weight: .bold)
        self.label.snp.makeConstraints{ make in
            make.left.right.equalToSuperview()
            make.centerY.equalToSuperview()
        }
    }
}

final public class H4Title: NSLoadView {
    
    public var text: String {
        get { label.stringValue } set { label.stringValue = newValue }
    }
    public var color: NSColor {
        get { label.textColor ?? .textColor } set { label.textColor = newValue }
    }
    public var isSelectable: Bool {
        get { label.isSelectable } set { label.isSelectable = newValue }
    }
    
    private let label = NSTextField(labelWithString: "H4 Title")
    
    public convenience init(text: String) {
        self.init()
        self.text = text
    }
    
    public override func onAwake() {
        self.snp.makeConstraints{ make in
            make.height.equalTo(28)
        }
        
        self.addSubview(label)
        self.label.textColor = .textColor
        self.label.font = .systemFont(ofSize: 16, weight: .bold)
        self.label.snp.makeConstraints{ make in
            make.left.right.equalToSuperview()
            make.centerY.equalToSuperview()
        }
    }
}

final public class H5Title: NSLoadView {
    
    public var text: String {
        get { label.stringValue } set { label.stringValue = newValue }
    }
    public var color: NSColor {
        get { label.textColor ?? .textColor } set { label.textColor = newValue }
    }
    public var isSelectable: Bool {
        get { label.isSelectable } set { label.isSelectable = newValue }
    }
    
    private let label = NSTextField(labelWithString: "H6 Title")
    
    public convenience init(text: String) {
        self.init()
        self.text = text
    }
    
    public override func onAwake() {
        self.snp.makeConstraints{ make in
            make.height.equalTo(26)
        }
        
        self.addSubview(label)
        self.label.textColor = .textColor
        self.label.font = .systemFont(ofSize: 14, weight: .bold)
        self.label.snp.makeConstraints{ make in
            make.left.right.equalToSuperview()
            make.centerY.equalToSuperview()
        }
    }
}


final public class H6Title: NSLoadView {
    
    public var text: String {
        get { label.stringValue } set { label.stringValue = newValue }
    }
    public var color: NSColor {
        get { label.textColor ?? .secondaryLabelColor } set { label.textColor = newValue }
    }
    public var isSelectable: Bool {
        get { label.isSelectable } set { label.isSelectable = newValue }
    }
    
    private let label = NSTextField(labelWithString: "H6 Title")
    
    public convenience init(text: String) {
        self.init()
        self.text = text
    }
    
    public override func onAwake() {
        self.snp.makeConstraints{ make in
            make.height.equalTo(24)
        }
        
        self.addSubview(label)
        self.label.textColor = .secondaryLabelColor
        self.label.font = .systemFont(ofSize: 14, weight: .bold)
        self.label.snp.makeConstraints{ make in
            make.left.right.equalToSuperview()
            make.centerY.equalToSuperview()
        }
    }
}
 
final public class Paragraph: NSLoadView {
    public var text: String = "Paragraph" { didSet { updateString() } }
    public var textColor: NSColor = .labelColor { didSet { updateString() } }
    
    public var isSelectable: Bool {
        get { label.isSelectable } set { label.isSelectable = newValue }
    }

    private let label = NSTextField(wrappingLabelWithString: "")
    
    private func updateString() {
        label.attributedStringValue = NSAttributedString(string: text, attributes: [
            .kern: 0.1,
            .font: NSFont.systemFont(ofSize: 15, weight: .regular),
            .foregroundColor: textColor,
            .paragraphStyle: NSMutableParagraphStyle() => {
                $0.minimumLineHeight = 22
            }
        ])
    }
    
    public convenience init(text: String) {
        self.init()
        self.text = text
        self.updateString()
    }
    
    public override func onAwake() {
        self.addSubview(label)
        
        self.label.allowsEditingTextAttributes = true
        
        self.label.snp.makeConstraints{ make in
            make.edges.equalToSuperview()
        }
        
        self.updateString()
    }
}

