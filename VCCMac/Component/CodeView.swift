//
//  CodeView.swift
//  VCCMac
//
//  Created by yuki on 2023/01/04.
//

import CoreUtil

final class CodeView: NSLoadView {
    var string: String { get { textView.stringValue } set { textView.stringValue = newValue } }
    
    private let backgroundView = NSRectangleView()
    private let textView = NSTextField(wrappingLabelWithString: "echo hello world")
    
    override func onAwake() {
        self.addSubview(backgroundView)
        self.backgroundView.cornerRadius = 3
        self.backgroundView.fillColor = NSColor.controlBackgroundColor.withAlphaComponent(0.3)
        self.backgroundView.borderWidth = 1
        self.backgroundView.borderColor = NSColor.systemGray.withAlphaComponent(0.2)
        self.backgroundView.snp.makeConstraints{ make in
            make.edges.equalToSuperview()
        }
        
        self.addSubview(textView)
        self.textView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        self.textView.snp.makeConstraints{ make in
            make.edges.equalToSuperview().inset(8)
        }
    }
}
