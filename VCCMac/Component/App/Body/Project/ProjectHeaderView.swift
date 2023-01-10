//
//  ProjectHeaderView.swift
//  VCCMac
//
//  Created by yuki on 2022/12/29.
//

import CoreUtil

final class ProjectHeaderView: NSLoadVisualEffectView {
    let reloadButton = SectionButton(image: R.image.reload())
    let projectTypePicker = EnumSelectionBar<ProjectFilterType>()
    let projectLegacyTypePicker = EnumPopupButton<ProjectLegacyFilterType>()
    let openButton = Button(title: R.localizable.open()) => { $0.backgroundColor = .systemGray }
    let newButton = Button(title: R.localizable.newProject(), image: R.image.addProject()) => {
        $0.contentTintColor = .white
    }
    let separator = NSBox() => { $0.boxType = .separator }
    
    override func onAwake() {
        self.material = .contentBackground
        
        self.snp.makeConstraints{ make in
            make.height.equalTo(42)
        }
        
        let stackView = NSStackView() => {
            $0.edgeInsets = .init(x: 8, y: 8)
        }
        stackView.distribution = .equalSpacing
        self.addSubview(stackView)
        stackView.snp.makeConstraints{ make in
            make.edges.equalToSuperview()
        }
        
        stackView.addArrangedSubview(reloadButton)
        stackView.addArrangedSubview(VSeparatorView())
        stackView.addArrangedSubview(projectTypePicker)
        stackView.addArrangedSubview(VSeparatorView())
        stackView.addArrangedSubview(NSTextField(labelWithString: R.localizable.type()) => {
            $0.textColor = .secondaryLabelColor
            $0.font = .systemFont(ofSize: 10.5, weight: .medium)
        })
        stackView.addArrangedSubview(projectLegacyTypePicker)
        stackView.addArrangedSubview(NSView())
        stackView.addArrangedSubview(openButton)
        stackView.addArrangedSubview(newButton)
        
        self.projectTypePicker.addAllItems()
        self.projectTypePicker.selectedItem = .all
        
        self.projectLegacyTypePicker.selectedItem = .all
        
        self.projectLegacyTypePicker.snp.makeConstraints{ make in
            make.width.equalTo(100)
        }
        
        self.addSubview(separator)
        self.separator.snp.makeConstraints{ make in
            make.left.right.bottom.equalToSuperview()
        }
    }
}
