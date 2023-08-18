//
//  Button.swift
//  DevToys
//
//  Created by yuki on 2022/02/01.
//

import CoreUtil

final public class Button: NSLoadButton {
    public override var title: String {
        didSet { titleLabel.stringValue = title }
    }
    public override var image: NSImage? {
        didSet { self.updateImageView() }
    }
    public override var imagePosition: NSControl.ImagePosition {
        didSet { self.updateImageView() }
    }
    public var backgroundColor: NSColor = NSColor.controlAccentColor {
        didSet { self.needsDisplay = true }
    }
    public var insets: NSEdgeInsets {
        get { self.stackView.edgeInsets } set { self.stackView.edgeInsets = newValue }
    }
    public override var isEnabled: Bool {
        didSet { self.alphaValue = isEnabled ? 1 : 0.2 }
    }
    
    public override var intrinsicContentSize: NSSize {
        stackView.intrinsicContentSize
    }
     
    private let stackView = NSStackView()
    private let iconView = NSImageView()
    private let titleLabel = NSTextField(labelWithString: "Button")
    
    private func updateImageView() {
        guard let image = image else {
            self.iconView.image = nil
            self.iconView.isHidden = true
            return
        }
        
        self.iconView.image = image.image(with: .white)
        
        self.iconView.isHidden = false
        self.titleLabel.isHidden = false
        
        self.stackView.arrangedSubviews.forEach{
            self.stackView.removeArrangedSubview($0)
        }
        
        switch imagePosition {
        case .noImage: self.iconView.isHidden = true
        case .imageOnly: self.titleLabel.isHidden = true
        case .imageLeft:
            self.stackView.orientation = .horizontal
            self.stackView.addArrangedSubview(iconView)
            self.stackView.addArrangedSubview(titleLabel)
        case .imageRight:
            self.stackView.orientation = .horizontal
            self.stackView.addArrangedSubview(titleLabel)
            self.stackView.addArrangedSubview(iconView)
        case .imageBelow:
            self.stackView.orientation = .vertical
            self.stackView.addArrangedSubview(titleLabel)
            self.stackView.addArrangedSubview(iconView)
        case .imageAbove:
            self.stackView.orientation = .vertical
            self.stackView.addArrangedSubview(iconView)
            self.stackView.addArrangedSubview(titleLabel)
        case .imageOverlaps:
            fatalError("Button not support imageOverlaps.")
        case .imageLeading:
            self.stackView.orientation = .horizontal
            self.stackView.addArrangedSubview(iconView)
            self.stackView.addArrangedSubview(titleLabel)
        case .imageTrailing:
            self.stackView.orientation = .horizontal
            self.stackView.addArrangedSubview(titleLabel)
            self.stackView.addArrangedSubview(iconView)
        @unknown default:
            self.stackView.orientation = .horizontal
            self.stackView.addArrangedSubview(iconView)
            self.stackView.addArrangedSubview(titleLabel)
        }
    }
    
    public override func drawFocusRingMask() {
        NSBezierPath(roundedRect: bounds, xRadius: R.size.corner, yRadius: R.size.corner).fill()
    }
    
    public override func draw(_ dirtyRect: NSRect) {
        var color = backgroundColor
        if isHighlighted { color = backgroundColor.shadow(withLevel: 0.1)! }
        
        color.setFill()
        
        NSBezierPath(roundedRect: bounds, xRadius: R.size.corner, yRadius: R.size.corner).fill()
    }
    
    public override func onAwake() {
        self.isBordered = false
        self.bezelStyle = .rounded
        self.snp.makeConstraints{ make in
            make.height.equalTo(R.size.controlHeight)
        }
        
        self.addSubview(stackView)
        self.stackView.spacing = 4
        self.stackView.distribution = .fill
        self.stackView.snp.makeConstraints{ make in
            make.top.bottom.equalToSuperview()
            make.left.right.greaterThanOrEqualToSuperview().inset(12).priority(.low)
            make.centerX.equalToSuperview()
        }
        
        self.stackView.addArrangedSubview(iconView)
        self.iconView.snp.makeConstraints{ make in
            make.size.equalTo(18)
        }
        
        self.stackView.addArrangedSubview(titleLabel)
        self.titleLabel.textColor = .white
        self.titleLabel.font = .systemFont(ofSize: 12)
        
        self.imagePosition = .imageLeft
    }
}

extension NSImage {
    public func image(with tintColor: NSColor) -> NSImage {
        if !self.isTemplate { return self }
        
        let image = self.copy() as! NSImage
        image.lockFocus()
        tintColor.set()
        let imageRect = NSRect(origin: .zero, size: image.size)
        imageRect.fill(using: .sourceIn)
        image.unlockFocus()
        image.isTemplate = false
        return image
    }
}

