//
//  ReposContainerView+.swift
//  VCCMac
//
//  Created by yuki on 2023/01/01.
//

import CoreUtil

final class ReposContainerViewController: NSViewController {
    private let cell = NSPlaceholderView()
    
    private let repoViewContainer = NSStackView()
    private let repoViewController = ReposViewController()
    private let legacyUnavailableViewController = ErrorTextViewController(title: R.localizable.packageIsUnavailableForLegacyProject())
    
    private let localPackageSeparator = NSBox() => {
        $0.boxType = .separator
    }
    private let addLocalPackageButton = Button(title: "Add Local Package")
    
    override func loadView() {
        self.view = cell
        self.addChild(legacyUnavailableViewController)
        self.addChild(repoViewController)
        
        self.repoViewContainer.orientation = .vertical
        self.repoViewContainer.addArrangedSubview(repoViewController.view)
        self.repoViewController.view.snp.makeConstraints{ make in
            make.top.left.right.equalToSuperview()
        }
//        self.repoViewContainer.addArrangedSubview(localPackageSeparator)
//        self.repoViewContainer.setCustomSpacing(0, after: repoViewController.view)
//        
//        self.repoViewContainer.addArrangedSubview(addLocalPackageButton)
//        self.addLocalPackageButton.snp.makeConstraints{ make in
//            make.bottom.left.right.equalToSuperview().inset(8)
//        }
    }
    
    override func chainObjectDidLoad() {
        let project = self.appSuccessModelPublisher.map{ $0.$selectedProject }.switchToLatest().compactMap{ $0 }
        let repo = appSuccessModelPublisher.map{ $0.$selectedRepo }.switchToLatest()
        
        project
            .sink{[unowned self] in
                $0.projectType
                    .peek{[self] in
                        if $0.isLegacy {
                            self.cell.contentView = legacyUnavailableViewController.view
                        } else {
                            self.cell.contentView = repoViewContainer
                        }
                    }
                    .catch{ self.appModel.logger.error($0) }
            }
            .store(in: &objectBag)

        
    }
}
