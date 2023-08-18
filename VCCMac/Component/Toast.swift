//
//  ACToast.swift
//  AxComponents
//
//  Created by yuki on 2021/09/13.
//  Copyright © 2021 yuki. All rights reserved.
//

import Cocoa
import CoreUtil
import DequeModule
import UserNotifications

final public class Toast: NSObject {
    public var message: String {
        get { toastWindow.message } set { assert(Thread.isMainThread); toastWindow.message = newValue }
    }
    public var action: Action? {
        get { toastWindow.action } set { assert(Thread.isMainThread); toastWindow.action = newValue }
    }
    public var color: NSColor? {
        get { toastWindow.color } set { assert(Thread.isMainThread); toastWindow.color = newValue }
    }
    public var closePublisher: some Publisher<Void, Never> {
        return closeSubject
    }
    
    public private(set) var isCurrentToast = false
    public private(set) static var currentToast: Toast?
    
    private let toastWindow = ToastWindow()
    private var showingOption: ShowingOption?
    private let closeSubject = PassthroughSubject<Void, Never>()
    
    public enum ShowingOption {
        case duration(CGFloat)
        case whileDeinit
        case promise(Promise<Void, Error>)
    }
    
    private static var pendingToasts = Deque<Toast>()
    
    public convenience init(message: String, action: Action? = nil, color: NSColor? = nil) {
        self.init()
        self.message = message
        self.action = action
        self.color = color
    }
    
    public enum AttributeViewPosition {
        case left, right, bottom
    }
    
    public func addAttributeView(_ view: NSView, position: AttributeViewPosition) {
        assert(Thread.isMainThread)
        toastWindow.addAttributeView(view, position: position)
    }
    
    @discardableResult
    public func show(_ option: ShowingOption) -> Toast {
        assert(Thread.isMainThread)
        if Toast.currentToast != nil { Toast.pendingToasts.append(self); return self }
        
        self.toastWindow.show()
        self.isCurrentToast = true
        self.showingOption = option
        Toast.currentToast = self
        
        switch option {
        case .duration(let duration):
            DispatchQueue.main.asyncAfter(deadline: .now()+duration) {
                self.close()
            }
        case .promise(let promise):
            promise.receive(on: .main).finally {
                self.close()
            }
        case .whileDeinit: break
        }
        return self
    }
    
    @discardableResult
    public func show<T, F>(untilComplete promise: Promise<T, F>) -> Toast {
        self.show(.promise(promise.eraseToVoid().eraseToError()))
        return self
    }
    
    @discardableResult
    public func show(for duration: TimeInterval = 3) -> Toast {
        self.show(.duration(duration))
        return self
    }
    
    public func close() {
        assert(Thread.isMainThread)
        defer {
            self.closeSubject.send()
        }
        guard self.isCurrentToast else { return }
        
        self.toastWindow.closeToast()
        self.isCurrentToast = false
        self.showingOption = nil
        Toast.currentToast = nil
        
        guard let nextToast = Toast.pendingToasts.popFirst() else { return }
        nextToast.show()
    }
    
    deinit {
        self.close()
    }
}

extension Toast {
    public convenience init(error: Error) {
        self.init(message: "\(error)", color: .systemRed)
    }
    
    public func addSpinningIndicator() {
        let indicator = NSProgressIndicator()
        indicator.style = .spinning
        indicator.startAnimation(nil)
        indicator.snp.makeConstraints{ make in
            make.size.equalTo(16)
        }
        self.addAttributeView(indicator, position: .right)
    }
    
    public func addCancelButton() -> NSButton {
        let cancelButton = NSButton(title: "", image: R.image.cancel())
        cancelButton.isBordered = false
        self.addAttributeView(cancelButton, position: .right)
        return cancelButton
    }
    
    public func addSpinningProgressIndicator(_ progress: Progress) {
        let indicator = NSProgressIndicator()
        indicator.minValue = 0
        indicator.maxValue = 1
        indicator.style = .spinning
        indicator.isIndeterminate = false
        indicator.controlSize = .small
        indicator.startAnimation(nil)
        
        progress.publisher(for: \.fractionCompleted).receive(on: DispatchQueue.main)
            .sink{ indicator.doubleValue = $0 }.store(in: &self.objectBag)
        
        self.addAttributeView(indicator, position: .right)
    }
    
    public func addBarProgressIndicator(_ progress: Progress) {
        let indicator = NSProgressIndicator()
        indicator.minValue = 0
        indicator.maxValue = 1
        indicator.style = .bar
        indicator.isIndeterminate = false
        indicator.snp.makeConstraints{ make in
            make.width.equalTo(200)
        }
        
        progress.publisher(for: \.fractionCompleted).receive(on: DispatchQueue.main)
            .sink{ indicator.doubleValue = $0 }.store(in: &self.objectBag)
        
        self.addAttributeView(indicator, position: .bottom)
    }
    
    @discardableResult
    public func addCloseButton() -> NSButton {
        let closeButton = NSButton(title: "", image: R.image.modal_close())
        closeButton.isBordered = false
        self.addAttributeView(closeButton, position: .left)
        closeButton.actionPublisher
            .sink{ self.close() }.store(in: &self.objectBag)
        return closeButton
    }
    
    public func addSubtitleLabel(_ initialMessage: String = "") -> NSTextField {
        let label = NSTextField(labelWithString: initialMessage)
        label.font = .systemFont(ofSize: 10)
        label.textColor = .secondaryLabelColor
        label.lineBreakMode = .byTruncatingTail
        self.addAttributeView(label, position: .bottom)
        return label
    }
}

final private class ToastWindow: NSPanel {
    private let toastView = ToastView()
    
    var message: String {
        get { toastView.message } set { toastView.message = newValue; updateLayout() }
    }
    var action: Action? {
        get { toastView.action } set { toastView.action = newValue; updateLayout() }
    }
    var color: NSColor? {
        get { toastView.color } set { toastView.color = newValue; updateLayout() }
    }
    
    func addAttributeView(_ view: NSView, position: Toast.AttributeViewPosition) {
        self.toastView.addAttributeView(view, position: position)
        self.updateLayout()
    }
    
    func show() {
        self.level = .floating
        self.appearance = NSAppearance(named: .darkAqua)
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.orderFrontRegardless()
        
        self.alphaValue = 0
        self.animator().alphaValue = 1
        
        self.updateLayout()
    }
    
    private func updateLayout() {
        guard let screen = NSScreen.main else { return NSSound.beep() }
        
        self.layoutIfNeeded()
        let frame = CGRect(centerX: screen.frame.size.width / 2, originY: 120, size: self.frame.size)
        self.setFrame(frame, display: true)
    }
    
    func closeToast() {
        self.animator().alphaValue = 0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.close()
        }
    }
    
    init() {
        super.init(contentRect: .zero, styleMask: [.nonactivatingPanel, .fullSizeContentView], backing: .buffered, defer: true)
        self.contentView = toastView
        self.hasShadow = false
        self.backgroundColor = .clear
        
        self.toastView.layoutPublsher
            .sink{[unowned self] in updateLayout() }.store(in: &objectBag)
    }
}

final private class ToastView: NSLoadView {
    
    var message: String {
        get { textField.stringValue } set { textField.stringValue = newValue }
    }
    var action: Action? {
        didSet { reloadAction() }
    }
    var color: NSColor? {
        didSet { reloadColor() }
    }
    
    override func layout() {
        super.layout()
        self.layoutPublsher.send()
    }
    
    func addAttributeView(_ view: NSView, position: Toast.AttributeViewPosition) {
        switch position {
        case .right: stackView.addArrangedSubview(view)
        case .left: stackView.insertArrangedSubview(view, at: 0)
        case .bottom: verticalStackView.addArrangedSubview(view)
        }
    }
    
    private func reloadAction() {
        actionButton.isHidden = action == nil
        actionButton.title = action?.title ?? ""
    }
    
    private func reloadColor() {
        colorView.fillColor = color ?? .clear
    }
    
    fileprivate var layoutPublsher = PassthroughSubject<Void, Never>()
    private let verticalStackView = NSStackView()
    private let stackView = NSStackView()
    private let textField = NSTextField(labelWithString: "Title")
    private let backgroundView = NSVisualEffectView()
    private let colorView = NSRectangleView()
    private let actionButton = ToastButton(title: "Button")
        
    convenience init(message: String) {
        self.init()
        self.textField.stringValue = message
    }
    
    @objc private func executeAction(_: Any) {
        action?.action()
    }
    
    override func onAwake() {
        self.wantsLayer = true
        self.layer?.cornerRadius = 10

        self.snp.makeConstraints{ make in
            make.width.lessThanOrEqualTo(420)
        }
        
        self.addSubview(backgroundView)
        self.backgroundView.state = .active
        self.backgroundView.material = .sidebar
        self.backgroundView.snp.makeConstraints{ make in
            make.edges.equalToSuperview()
        }
        
        self.addSubview(colorView)
        self.colorView.alphaValue = 0.85
        self.colorView.snp.makeConstraints{ make in
            make.edges.equalToSuperview()
        }
        
        self.addSubview(verticalStackView)
        self.verticalStackView.orientation = .vertical
        self.verticalStackView.alignment = .centerX
        self.verticalStackView.snp.makeConstraints{ make in
            make.edges.equalToSuperview().inset(16)
        }
        
        self.verticalStackView.addArrangedSubview(stackView)
        
        self.stackView.addArrangedSubview(textField)
        self.textField.alignment = .center
        self.textField.lineBreakMode = .byWordWrapping
        self.textField.textColor = .white
                
        self.stackView.addArrangedSubview(actionButton)
        self.actionButton.bezelStyle = .inline
        self.actionButton.setTarget(self, action: #selector(executeAction))
        
        self.reloadAction()
    }
}

final private class ToastButton: NSLoadButton {
    override var intrinsicContentSize: NSSize {
        super.intrinsicContentSize + [4, 4]
    }
    
    override func draw(_ dirtyRect: NSRect) {
        
        if isHighlighted {
            NSColor.black.withAlphaComponent(0.3).setFill()
        } else {
            NSColor.black.withAlphaComponent(0.2).setFill()
        }
        NSBezierPath(roundedRect: bounds, xRadius: bounds.height/2, yRadius: bounds.height/2).fill()
        
        let nsString = title as NSString
        nsString.draw(center: bounds, attributes: [
            .foregroundColor : NSColor.secondaryLabelColor,
            .font : NSFont.systemFont(ofSize: NSFont.smallSystemFontSize, weight: .medium)
        ])
    }
    
    override func onAwake() {
        self.bezelStyle = .inline
    }
}
