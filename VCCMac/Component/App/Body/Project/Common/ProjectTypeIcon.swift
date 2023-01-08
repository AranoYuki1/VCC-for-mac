//
//  ProjectTypeIcon.swift
//  VCCMac
//
//  Created by yuki on 2022/12/30.
//

import CoreUtil

final class ProjectTypeIcon: NSLoadView {
    var color: NSColor = .systemOrange { didSet { needsDisplay = true } }
    var icon: NSImage? = nil { didSet { iconView.image = icon } }
    var isLoading = true { didSet { needsDisplay = true } }
    var isLegacy = false {
        didSet {  }
    }
    
    private let iconView = NSImageView()
    private let backgroundView = NSCapsule()
    private let indicator = NSProgressIndicator() => {
        $0.style = .spinning
    }
    
    func setProjectType(_ type: ProjectType) {
        assert(Thread.isMainThread)
        self.color = type.color
        self.icon = type.icon
        self.isLoading = false
    }
    
    override func updateLayer() {
        if isLoading {
            self.backgroundView.fillColor = NSColor.systemGray.blended(withFraction: 0.4, of: .white)
            self.backgroundView.borderColor = self.backgroundView.fillColor?.shadow(withLevel: 0.1)
            self.indicator.isHidden = false
            self.indicator.startAnimation(nil)
            self.iconView.isHidden = true
        } else {
            self.backgroundView.fillColor = color
            self.backgroundView.borderColor = self.backgroundView.fillColor?.shadow(withLevel: 0.1)
            self.indicator.isHidden = true
            self.indicator.stopAnimation(nil)
            self.iconView.isHidden = false
        }
    }
    
    override func onAwake() {
        self.snp.makeConstraints{ make in
            make.size.equalTo(40)
        }
        
        self.addSubview(backgroundView)
        self.backgroundView.snp.makeConstraints{ make in
            make.edges.equalToSuperview()
        }
        
        self.addSubview(iconView)
        self.iconView.contentTintColor = .white
        self.iconView.snp.makeConstraints{ make in
            make.edges.equalToSuperview().inset(2)
        }
        
        self.addSubview(indicator)
        self.indicator.snp.makeConstraints{ make in
            make.edges.equalToSuperview().inset(12)
        }        
    }
}
