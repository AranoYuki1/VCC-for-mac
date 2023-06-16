//
//  PackageCell.swift
//  VCCMac
//
//  Created by yuki on 2022/12/30.
//

import CoreUtil

final class PackageCell: NSLoadView {
    let titleLabel = NSTextField(labelWithString: "") => {
        $0.font = .systemFont(ofSize: 13, weight: .medium)
    }
    let identifierLabel = NSTextField(labelWithString: "") => {
        $0.font = .systemFont(ofSize: 10.5)
        $0.textColor = .secondaryLabelColor
    }
    let descriptionLabel = NSTextField(wrappingLabelWithString: "") => {
        $0.font = .systemFont(ofSize: 12)
        $0.textColor = .secondaryLabelColor
    }
    let versionPicker = PopupButton()
    var existingPackage = false {
        didSet {
            self.addButton.isHidden = existingPackage
            self.removeButton.isHidden = !existingPackage
        }
    }
    
    let addButton = Button(title: R.localizable.add())
    let removeButton = Button(title: R.localizable.remove()) => { $0.backgroundColor = .systemRed }
    let updateButton = Button(title: R.localizable.update())
    
    private let stackView = NSStackView()
    
    override func onAwake() {
        self.addSubview(stackView)
        self.stackView.edgeInsets = .init(x: 8, y: 12)
        
        self.stackView.orientation = .vertical
        self.stackView.alignment = .left
        self.stackView.snp.makeConstraints{ make in
            make.edges.equalToSuperview()
        }
        
        self.stackView.addArrangedSubview(NSStackView() => {
            $0.spacing = 4
            $0.alignment = .left
            $0.addArrangedSubview(titleLabel)
            $0.addArrangedSubview(identifierLabel)
        })
        self.stackView.addArrangedSubview(descriptionLabel => {
            $0.setContentCompressionResistancePriority(.init(1), for: .horizontal)
        })
        self.stackView.addArrangedSubview(NSStackView() => {
            $0.addArrangedSubview(versionPicker)
            $0.addArrangedSubview(NSView() => {
                $0.setContentHuggingPriority(.defaultLow, for: .horizontal)
            })
            $0.addArrangedSubview(addButton)
            $0.addArrangedSubview(removeButton)
//            $0.addArrangedSubview(updateButton)
            removeButton.isHidden = true
            
            self.versionPicker.snp.makeConstraints{ make in
                make.width.equalTo(120)
            }
        })
        
        let separator = NSBox()
        separator.boxType = .separator
        self.addSubview(separator)
        separator.snp.makeConstraints{ make in
            make.left.right.bottom.equalToSuperview()
        }
    }
}
