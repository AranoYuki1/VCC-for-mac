//
//  ProjectDetailHeaderView.swift
//  VCCMac
//
//  Created by yuki on 2022/12/30.
//

import CoreUtil

final class ProjectDetailHeaderView: NSLoadVisualEffectView {
    let titleLabel = NSTextField(labelWithString: "") => {
        $0.font = .systemFont(ofSize: 17, weight: .semibold)
    }
    let pathLabel = NSTextField(labelWithString: "") => {
        $0.font = .systemFont(ofSize: 11)
        $0.textColor = .secondaryLabelColor
    }
    let dateLabel = NSTextField(labelWithString: "") => {
        $0.font = .systemFont(ofSize: 11)
        $0.textColor = .secondaryLabelColor
    }
    let typeLabel = ProjectTypeLabel()
    let menuButton = MenuButton()
    
    private let stackView = NSStackView()
    private let separator = NSBox() => {
        $0.boxType = .separator
    }
    
    override func onAwake() {
        self.material = .contentBackground
        
        self.pathLabel.lineBreakMode = .byTruncatingMiddle
        self.pathLabel.usesSingleLineMode = true
        self.pathLabel.cell?.truncatesLastVisibleLine = true
        
        self.addSubview(stackView)
        self.stackView.alignment = .left
        self.stackView.orientation = .vertical
        self.stackView.edgeInsets = .init(x: 12, y: 16)
        self.stackView.addArrangedSubview(titleLabel)
        
        self.stackView.snp.makeConstraints{ make in
            make.edges.equalToSuperview()
        }
        
        self.stackView.addArrangedSubview(NSStackView() => {
            $0.addArrangedSubview(typeLabel)
            $0.addArrangedSubview(dateLabel)
            $0.addArrangedSubview(NSView())
        })
        
        let container = NSView()
        self.stackView.addArrangedSubview(container => {
            $0.addSubview(pathLabel)
            $0.addSubview(menuButton)
            self.pathLabel.isHorizontalContentSizeConstraintActive = false
            self.pathLabel.snp.makeConstraints{ make in
                make.left.centerY.equalToSuperview()
                make.right.equalTo(menuButton.snp.left).inset(-12)
            }
            self.menuButton.snp.makeConstraints{ make in
                make.right.centerY.equalToSuperview()
            }
        })
        container.snp.makeConstraints{ make in
            make.height.equalTo(32)
            make.left.right.equalToSuperview().inset(12)
        }
                    
        self.addSubview(separator)
        self.separator.snp.makeConstraints{ make in
            make.left.right.bottom.equalToSuperview()
        }
    }
}

