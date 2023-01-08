//
//  ProjectDetailContainer+.swift
//  VCCMac
//
//  Created by yuki on 2022/12/30.
//

import CoreUtil

final class ProjectDetailContainerViewController: NSViewController {
    let detailViewController = ProjectDetailViewController()
    let noProjectViewController = ErrorTextViewController(title: R.localizable.noProject())
    let placeholder = NSPlaceholderView()
    
    override func loadView() {
        self.addChild(detailViewController)
        self.addChild(noProjectViewController)
        self.view = placeholder
    }
    
    override func chainObjectDidLoad() {
        self.appSuccessModelPublisher.map{ $0.$selectedProject }.switchToLatest()
            .sink{[unowned self] in
                if $0 == nil {
                    self.placeholder.contentView = noProjectViewController.view
                } else {
                    self.placeholder.contentView = detailViewController.view
                }
            }
            .store(in: &objectBag)
        
        self.placeholder.contentView = noProjectViewController.view
    }
}

final class ErrorTextViewController: NSViewController {
    convenience init(title: String) {
        self.init()
        self.title = title
    }
    
    override func loadView() {
        self.view = NSView()
        
        let label = NSTextField(wrappingLabelWithString: self.title ?? "Error") => {
            $0.alignment = .center
            $0.textColor = .secondaryLabelColor
        }
        self.view.addSubview(label)
        label.snp.makeConstraints{ make in
            make.left.right.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
    }
}

