//
//  ConsoleWindow.swift
//  VCCMac
//
//  Created by yuki on 2023/08/17.
//

import CoreUtil

extension Logger.Level {
    var color: NSColor {
        switch self {
        case .debug: return .systemGray
        case .info: return .systemBlue
        case .log: return .systemGreen
        case .warn: return .systemOrange
        case .error: return .systemRed
        }
    }
}

class ConsoleWindow: ModalWindow {
    
    static let shared = ConsoleWindow()
    
    private var _contentViewController: ConsoleViewController {
        self.contentViewController as! ConsoleViewController
    }
    
    func show() {
        self.makeKeyAndOrderFront(self)
    }
    
    func append(_ string: String, color: NSColor) {
        self._contentViewController.append(string, color: color)
    }
    
    func append(_ log: Logger.Log) {
        self.append(log.description, color: log.level.color)
    }
    
    convenience init() {
        self.init(contentViewController: ConsoleViewController())
        self.identifier = .init("ConsoleWindow")
        self.setFrameAutosaveName("ConsoleWindow")
        
        self.minSize = .init(width: 500, height: 300)
        self.setContentSize(.init(width: 700, height: 300))
        
        self.title = "Console"
    }
}

final private class ConsoleViewController: NSViewController {
    private let cell = ConsoleView()
    
    override func loadView() { self.view = cell }
    
    func append(_ string: String, color: NSColor) {
        
        
        self.cell.textView.textView.textStorage?.append(
            NSAttributedString(string: string, attributes: [
                .foregroundColor: color,
                .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .semibold)
            ])
        )
        self.cell.textView.textView.textStorage?.append(NSAttributedString(string: "\n"))

        self.cell.textView.scrollToBottomIfNeeded()
    }
    
    override func viewDidLoad() {
        self.cell.headerView.clearButton.actionPublisher
            .sink{[unowned self] in self.cell.textView.clear() }.store(in: &objectBag)
    }
}

final private class ConsoleView: NSLoadStackView {
    let headerView = ConsoleHeaderView()
    let textView = ConsoleTextView()
    
    override func onAwake() {
        self.orientation = .vertical
        self.spacing = 0
        self.addArrangedSubview(textView)
        self.addArrangedSubview(NSBox() => {
            $0.boxType = .separator
        })
        self.addArrangedSubview(headerView)
    }
}

final private class ConsoleHeaderView: NSLoadStackView {
    let clearButton = NSButton(image: R.image.trash())
    
    override func onAwake() {
        self.orientation = .horizontal
        self.distribution = .fill
        self.snp.makeConstraints{ make in
            make.height.equalTo(30)
        }
        
        self.clearButton.imageScaling = .scaleProportionallyUpOrDown
        self.clearButton.isBordered = false
        self.clearButton.snp.makeConstraints{ make in
            make.width.height.equalTo(18)
        }
    
        self.edgeInsets = .init(x: 10, y: 0)
        self.addArrangedSubview(NSView())
        self.addArrangedSubview(clearButton)
    }
}

extension NSScrollView {
    // そのうちCoreUtilに移動
    public var documentOffset: NSPoint {
        set { documentView?.scroll(newValue) }
        get { documentVisibleRect.origin }
    }
}

final private class ConsoleTextView: NSLoadView {
    let scrollView = NSTextView.scrollableTextView()
    var textView: NSTextView { scrollView.documentView as! NSTextView }
    
    func clear() {
        self.textView.string = ""
    }
    
    func scrollToBottomIfNeeded() {
        let offset = self.scrollView.documentVisibleRect.minY + self.scrollView.documentVisibleRect.height
        if abs(offset - self.textView.frame.height) < 20 {
            self.textView.scrollToEndOfDocument(nil)
        }
    }
    
    override func onAwake() {
        self.addSubview(scrollView)
        self.scrollView.snp.makeConstraints{ make in
            make.edges.equalToSuperview()
        }
        
        self.textView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        self.textView.textColor = .labelColor
        self.textView.isEditable = false
        self.textView.isSelectable = true
        self.textView.isRichText = false
    }
}
