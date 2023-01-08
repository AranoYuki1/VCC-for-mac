//
//  NoteView.swift
//  VCCMac
//
//  Created by yuki on 2023/01/04.
//

import CoreUtil

struct NoteType {
    fileprivate let color: NSColor
    fileprivate let icon: NSImage
    
    static let info = NoteType(color: .systemGreen, icon: R.image.note.info())
    static let warn = NoteType(color: .systemYellow, icon: R.image.note.warn())
    static let alert = NoteType(color: .systemRed, icon: R.image.note.alert())
    
    init(color: NSColor, icon: NSImage) {
        self.color = color
        self.icon = icon
    }
}

final class NoteView: NSLoadView {
    var title: String { get { titleLabel.stringValue } set { titleLabel.stringValue = newValue } }
    var message: String { get { messageTextField.stringValue } set { messageTextField.stringValue = newValue } }
    
    var type: NoteType = .info { didSet { reloadType() } }
    
    private lazy var messageTextField = NSTextField(wrappingLabelWithString: "This is the message of the NoteView.") => {
        $0.font = .systemFont(ofSize: 13)
        $0.textColor = NSColor.textColor
        $0.alphaValue = 0.8
        self.stackView.addArrangedSubview($0)
    }

    
    func addNoteView(_ view: NSView) {
        self.stackView.addArrangedSubview(view)
    }
    
    convenience init(type: NoteType) {
        self.init()
        self.type = type
        self.reloadType()
    }
    
    private let backgroundView = NSRectangleView()
    private let iconView = NSImageView()
    private let stackView = NSStackView()
    private let titleLabel = NSTextField(labelWithString: "Title") => {
        $0.font = .systemFont(ofSize: 15, weight: .medium)
        $0.textColor = NSColor.textColor
        $0.alphaValue = 0.8
    }
    
    private func reloadType() {
        self.iconView.image = type.icon
        self.backgroundView.fillColor = type.color.withAlphaComponent(0.1)
    }
    
    override func onAwake() {
        self.addSubview(backgroundView)
        self.backgroundView.cornerRadius = 3
        self.backgroundView.snp.makeConstraints{ make in
            make.edges.equalToSuperview()
        }
        
        self.addSubview(stackView)
        self.stackView.orientation = .vertical
        self.stackView.alignment = .left
        self.stackView.spacing = 6
        self.stackView.edgeInsets = NSEdgeInsets(x: 12, y: 12)
        self.stackView.snp.makeConstraints{ make in
            make.top.right.bottom.equalToSuperview()
            make.left.equalToSuperview().inset(34)
        }
        self.stackView.addArrangedSubview(titleLabel)
                
        self.addSubview(iconView)
        self.iconView.image = R.image.note.alert()
        self.iconView.snp.makeConstraints{ make in
            make.size.equalTo(32)
            make.left.equalToSuperview().inset(8)
            make.centerY.equalToSuperview()
        }
        self.reloadType()
    }
}
