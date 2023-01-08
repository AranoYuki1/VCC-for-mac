//
//  ProjectTypeLabel.swift
//  VCCMac
//
//  Created by yuki on 2022/12/30.
//

import CoreUtil

final class ProjectTypeLabel: NSLoadStackView {
    var text: String = "" { didSet { setNeedsDisplay(bounds) } }
    var isLoading = true { didSet { setNeedsDisplay(bounds) } }
    var color: NSColor = .systemOrange { didSet { setNeedsDisplay(bounds) } }
    
    func setProjectType(_ type: ProjectType) {
        assert(Thread.isMainThread)
        self.isLoading = false
        self.text = type.title
        self.color = type.color
    }
    
    private let label = NSTextField(labelWithString: "") => {
        $0.font = .systemFont(ofSize: 10)
        $0.textColor = .white
    }
    private let loadingIndicator = NSProgressIndicator() => {
        $0.style = .spinning
    }
    
    override func layout() {
        super.layout()
        self.layer?.cornerRadius = frame.size.minElement/2
    }
    
    override func updateLayer() {
        if isLoading {
            self.layer?.backgroundColor = NSColor.systemGray.withAlphaComponent(0.8).cgColor
            self.layer?.borderColor = NSColor.systemGray.cgColor
        } else {
            self.layer?.backgroundColor = color.withAlphaComponent(0.8).cgColor
            self.layer?.borderColor = color.cgColor
        }
        
        if isLoading {
            self.loadingIndicator.startAnimation(nil)
            self.loadingIndicator.isHidden = false
            self.label.stringValue = R.localizable.loading()
        } else {
            self.loadingIndicator.stopAnimation(nil)
            self.loadingIndicator.isHidden = true
            self.label.stringValue = text
        }
    }
    override func onAwake() {
        self.wantsLayer = true
        self.layer?.borderWidth = 1
        self.spacing = 4
        self.edgeInsets.left = 8
        self.edgeInsets.right = 8
        
        self.addArrangedSubview(label)
        self.label.snp.makeConstraints{ make in
            make.top.bottom.equalToSuperview().inset(2)
        }
        
        self.addArrangedSubview(loadingIndicator)
        self.loadingIndicator.snp.makeConstraints{ make in
            make.size.equalTo(10)
        }
    }
}
