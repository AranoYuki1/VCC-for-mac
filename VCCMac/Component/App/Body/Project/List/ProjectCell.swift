//
//  ProjectCell.swift
//  VCCMac
//
//  Created by yuki on 2022/12/28.
//

import CoreUtil

final class ProjectCell: NSLoadStackView {
    static let cellHeight: CGFloat = 80
    
    let iconView = ProjectTypeIcon()
    let titleLabel = NSTextField(labelWithString: "Komado_Main") => {
        $0.font = .systemFont(ofSize: 13, weight: .semibold)
    }
    let pathLabel = NSTextField(labelWithString: "/Users/yuki/Desktop/VRChat/Project") => {
        $0.font = .systemFont(ofSize: 11)
        $0.textColor = .secondaryLabelColor
    }
    let dateLabel = NSTextField(labelWithString: "2022/12/4") => {
        $0.font = .systemFont(ofSize: 11)
        $0.textColor = .secondaryLabelColor
    }
    let typeLabel = ProjectTypeLabel()
    let menuButton = MenuButton()
    
    override func onAwake() {
        self.spacing = 16
        self.edgeInsets = .init(x: 8, y: 0)
        self.snp.makeConstraints{ make in
            make.height.equalTo(ProjectCell.cellHeight)
        }

        self.addArrangedSubview(iconView)
        self.iconView.icon = R.image.project.avatar()
        self.iconView.color = .systemOrange
        
        self.addArrangedSubview(NSStackView() => { view in
            view.alignment = .left
            view.orientation = .vertical
            view.addArrangedSubview(NSStackView() => { view in
                view.addArrangedSubview(titleLabel)
                view.addArrangedSubview(NSView() => {
                    $0.setContentHuggingPriority(.defaultLow, for: .horizontal)
                })
                view.addArrangedSubview(typeLabel)
                view.addArrangedSubview(dateLabel)
            })
            view.addArrangedSubview(NSStackView() => { view in
                view.addArrangedSubview(pathLabel)
                view.addArrangedSubview(NSView() => {
                    $0.setContentHuggingPriority(.defaultLow, for: .horizontal)
                })
            })
        })
        
        self.addArrangedSubview(menuButton)
    }
}
