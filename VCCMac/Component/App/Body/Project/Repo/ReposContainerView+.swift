//
//  ReposContainerView+.swift
//  VCCMac
//
//  Created by yuki on 2023/01/01.
//

import CoreUtil

final class ReposContainerViewController: NSViewController {
    private let cell = NSPlaceholderView()
    private let repoViewController = ReposViewController()
    private let legacyUnavailableViewController = ErrorTextViewController(title: R.localizable.packageIsUnavailableForLegacyProject())
    
    override func loadView() {
        self.view = cell
        self.addChild(legacyUnavailableViewController)
        self.addChild(repoViewController)
    }
    
    override func chainObjectDidLoad() {
        self.appSuccessModelPublisher.map{ $0.$selectedProject }.switchToLatest().compactMap{ $0 }
            .sink{[unowned self] in
                $0.projectType
                    .peek{[self] in
                        if $0.isLegacy {
                            self.cell.contentView = legacyUnavailableViewController.view
                        } else {
                            self.cell.contentView = repoViewController.view
                        }
                    }
                    .catch{ self.appModel.logger.error($0) }
            }
            .store(in: &objectBag)
    }
}
