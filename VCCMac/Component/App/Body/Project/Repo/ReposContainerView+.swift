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
    private let addLocalPackageButton = Button(title: "Add User Repo")
    
    override func loadView() {
        self.view = cell
        self.addChild(legacyUnavailableViewController)
        self.addChild(repoViewController)
        
        self.repoViewContainer.orientation = .vertical
        self.repoViewContainer.addArrangedSubview(repoViewController.view)
        self.repoViewController.view.snp.makeConstraints{ make in
            make.top.left.right.equalToSuperview()
        }
        self.repoViewContainer.addArrangedSubview(localPackageSeparator)
        self.repoViewContainer.setCustomSpacing(0, after: repoViewController.view)
        
        self.repoViewContainer.addArrangedSubview(addLocalPackageButton)
        self.addLocalPackageButton.snp.makeConstraints{ make in
            make.bottom.left.right.equalToSuperview().inset(8)
        }
    }
    
    override func chainObjectDidLoad() {
        let project = self.appSuccessModelPublisher.map{ $0.$selectedProject }.switchToLatest().compactMap{ $0 }
                
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
        
        self.addLocalPackageButton.actionPublisher
            .sink{ self.openAddPackageModal() }.store(in: &objectBag)
    }
    
    private func openAddPackageModal() {
        let alert = NSAlert()
        alert.messageText = "Enter URL of VCC Package"
        alert.informativeText = "Enter the URL to the repository. The repository will be added to VPM and will be available for future use."
        
        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 240, height: 22))
        textField.placeholderString = "https://example.com/vpm.json"
        alert.accessoryView = textField
        alert.addButton(withTitle: R.localizable.oK())
        alert.addButton(withTitle: R.localizable.cancel())

        guard alert.runModal() == .alertFirstButtonReturn else { return }
        
        guard let url = URL(string: textField.stringValue) else {
            appModel.logger.error("'\(textField.stringValue)' is not URL.")
            return
        }
        
        guard let model = self.appSuccessModel else { return }
        
        Toast(message: "Adding '\(url)'...")
            .show(untilComplete: model.packageManager.addRepogitory(url))
            .addSpinningIndicator()
        
        Toast(message: "Added '\(url)'").show()
    }
}
