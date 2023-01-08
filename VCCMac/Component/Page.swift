//
//  ToolPage.swift
//  DevToys
//
//  Created by yuki on 2022/01/30.
//

import CoreUtil

final class PageHeader: NSLoadView {
    private let titleView = H1Title()
    private let backgroundView = NSVisualEffectView()
    
    var title: String {
        get { titleView.text } set { titleView.text = newValue }
    }
    
    func addAccessoryView(_ view: NSView) {
        self.titleView.addAccessoryView(view)
    }
    
    fileprivate func setSeparatorHidden(_ isHidden: Bool) {
        if isHidden {
            self.shadow = NSShadow() => {
                $0.shadowColor = .clear
            }
        } else {
            self.animator().shadow = NSShadow() => {
                $0.shadowColor = NSColor.black.withAlphaComponent(0.2)
                $0.shadowBlurRadius = 1
                $0.shadowOffset = [0, -1]
            }
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        window?.performDrag(with: event)
    }
    override func mouseDragged(with event: NSEvent) {
        window?.performDrag(with: event)
    }
    override func mouseUp(with event: NSEvent) {
        window?.performDrag(with: event)
    }
    
    override func onAwake() {
        self.addSubview(backgroundView)
        self.backgroundView.material = .contentBackground
        self.backgroundView.snp.makeConstraints{ make in
            make.edges.equalToSuperview()
        }

        self.addSubview(titleView)
        self.titleView.font = .systemFont(ofSize: 20, weight: .semibold)
        self.titleView.snp.makeConstraints{ make in
            make.top.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(8)
            make.left.right.equalToSuperview().inset(16)
        }
    }
}

class Page: NSLoadView {
    
    private let header = PageHeader()
    let stackView = NSStackView()
    let scrollView = NSScrollView()
    
    var title: String {
        get { header.title } set { header.title = newValue }
    }
    
    func addAccessoryView(_ view: NSView) {
        self.header.addAccessoryView(view)
    }
    
    private func commonInit() {
        
        self.addSubview(scrollView)
//        self.addSubview(header)
//        self.header.isHidden = true
//
//        self.header.snp.makeConstraints{ make in
//            make.top.left.right.equalToSuperview()
//        }
//        self.scrollView.snp.makeConstraints{ make in
//            make.top.equalTo(header.snp.bottom)
//            make.left.right.bottom.equalToSuperview()
//        }
        
        self.scrollView.snp.makeConstraints{ make in
            make.edges.equalToSuperview()
        }

        self.stackView.edgeInsets = NSEdgeInsets(x: 16, y: 16)
        self.stackView.orientation = .vertical
        self.stackView.alignment = .left
        
        self.scrollView.contentView = FlipClipView()
        self.scrollView.documentView = stackView
                
        self.stackView.snp.makeConstraints{ make in
            make.top.equalToSuperview()
            make.right.left.equalToSuperview()
        }

        self.scrollView.offsetYPublisher
            .sink{[unowned self] in header.setSeparatorHidden($0 <= 0) }.store(in: &objectBag)
    }

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
}

extension Page {
    
    enum Alignment {
        case left, center, right, fullWidth
    }
    
    func addSection(_ section: NSView, alignment: Alignment = .fullWidth) {
        self.stackView.addArrangedSubview(section)
        
        switch alignment {
        case .fullWidth:
            section.snp.makeConstraints{ make in
                make.right.left.equalToSuperview().inset(16)
            }
        case .left:
            section.snp.makeConstraints{ make in
                make.left.equalToSuperview().inset(16)
            }
        case .right:
            section.snp.makeConstraints{ make in
                make.right.equalToSuperview().inset(16)
            }
        case .center:
            section.snp.makeConstraints{ make in
                make.centerX.equalToSuperview()
            }
        }
    }
    
    @discardableResult
    func addSection2(_ stack1: NSView, _ stack2: NSView) -> NSStackView {
        let stackView = NSStackView()
        stackView.distribution = .fillEqually
        stackView.orientation = .horizontal
        stackView.alignment = .top
        stackView.addArrangedSubview(stack1)
        stackView.addArrangedSubview(stack2)
        self.addSection(stackView)
        return stackView
    }
}

class FlipClipView: NSClipView {
    override var isFlipped: Bool { true }
}

extension NSScrollView {
    public var offsetYPublisher: some Publisher<CGFloat, Never> {
        self.contentView.documentVisibleRectPublisher
            .map{ -self.frame.size.height + (self.documentView?.frame.height ?? 0) - $0.origin.y }
    }
}

extension NSClipView {
    public var documentVisibleRectPublisher: some Publisher<CGRect, Never> {
        self.postsFrameChangedNotifications = true
        self.postsBoundsChangedNotifications = true
        return NotificationCenter.default.publisher(for: NSScrollView.boundsDidChangeNotification)
            .merge(with: NotificationCenter.default.publisher(for: NSScrollView.frameDidChangeNotification))
            .compactMap{ $0.object as? NSClipView }
            .filter{[unowned self] in $0 === self }
            .map{ $0.documentVisibleRect }
    }
}
