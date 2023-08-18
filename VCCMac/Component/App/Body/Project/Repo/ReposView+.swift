//
//  ReposView+.swift
//  VCCMac
//
//  Created by yuki on 2022/12/29.
//

import CoreUtil

final class ReposViewController: NSViewController {
    private let cell = ReposView()
    private let listViewController = ReposListViewController()
    
    override func loadView() {
        self.view = cell
        self.cell.listViewPlaceholder.contentView = listViewController.view
        self.addChild(listViewController)
    }
    
    private func updatePackages() {
        guard let model = self.appSuccessModel, let project = model.selectedProject, let manifest = project.manifest else { return }
        
        let packageManager = model.packageManager
        
        _ = Promise{
            try await packageManager.checkForUpdate().value
            
            for (name, package) in manifest.locked {
                guard let nextPackage = packageManager.findPackage(for: name) else { return }
                guard let maxVersion = nextPackage.versions.max(by: { $0.version < $1.version }) else { return }
                
                let toast = Toast(message: "Updating \(name)...").show(.whileDeinit)
                
                if package.version < maxVersion.version {
                    try await packageManager.removePackage(nextPackage, from: project).value
                    try await packageManager.addPackage(maxVersion, to: project).value
                }
                
                toast.close()
            }
        }
    }
    
    private func onRightClickMenu(_ view: NSView, repo: PackageManager.Repogitory) {
        let menu = NSMenu()
        
        menu.addItem(title: "Remove Repogitory") {[self] in
            guard let model = self.appSuccessModel else { return }
            
            let toast = Toast(message: "Removing \(repo.name)...")
            toast.addSpinningIndicator()
            toast.show(untilComplete: model.packageManager.removeRepogitory(repo.id))
            
            Toast(message: "Removed \(repo.name)").show()
        }
        
        if self.appModel.debug {
            menu.addItem(title: "Show Repogitory URL (Debug)") {
                self.appModel.logger.info(repo.url?.absoluteString ?? "")
            }
            
            menu.addItem(title: "Show Repogitory Info (Debug)") {
                for package in repo.packages {
                    self.appModel.logger.info("=======================")
                    self.appModel.logger.info(package.displayName)
                    for version in package.versions {
                        self.appModel.logger.info(String(describing: version))
                    }
                }
            }
        }
        
        menu.popUp(positioning: nil, at: .zero, in: view)
    }
    
    override func chainObjectDidLoad() {
        self.appSuccessModelPublisher.map{ $0.packageManager.$repos }.switchToLatest()
            .receive(on: DispatchQueue.main)
            .sink{[self] repos in
                let typePicker = cell.header.typePicker
                typePicker.removeAllItems()
                typePicker.addItem("Installed")
                repos.forEach{ repo in
                    if repo.isUserRepo {
                        typePicker.addItem(SelectionBar.Item(title: repo.name, rightAction: { view in
                            self.onRightClickMenu(view, repo: repo)
                        }))
                    } else {
                        typePicker.addItem(repo.name)
                    }
                }
            }
            .store(in: &objectBag)
        
        self.appSuccessModelPublisher.map{ $0.$repoIndex }.switchToLatest()
            .sink{
                switch $0 {
                case .installed: self.cell.header.typePicker.selectedItemIndex = 0
                case .local(let index): self.cell.header.typePicker.selectedItemIndex = index + 1
                }
            }
            .store(in: &objectBag)

        self.cell.header.typePicker.selectedIndexPublisher
            .sink{
                if $0 == 0 {
                    self.appSuccessModel?.repoIndex = .installed
                } else {
                    self.appSuccessModel?.repoIndex = .local($0 - 1)
                }
            }
            .store(in: &objectBag)
        
        self.cell.header.updateButton.actionPublisher
            .sink{[unowned self] in self.updatePackages() }.store(in: &objectBag)
    }
}

final class ReposHeader: NSLoadStackView {
    let separator = NSBox() => { $0.boxType = .separator }
    let titleLabel = NSTextField(labelWithString: "")
    let updateButton = Button(title: "Update All")
    let titleStackView = NSStackView()
    let typePicker = SelectionBar()
    
    override func onAwake() {
        self.addSubview(separator)
        self.separator.snp.makeConstraints{ make in
            make.top.left.right.equalToSuperview()
        }
        self.edgeInsets = .init(x: 10, y: 12)
        self.orientation = .vertical
        self.alignment = .left
        
        self.addArrangedSubview(titleStackView)
        self.titleStackView.orientation = .horizontal
        self.titleStackView.addArrangedSubview(titleLabel)
        self.titleLabel.attributedStringValue = NSAttributedString(
            string: R.localizable.packages().uppercased(), attributes: [
                .kern: 2.5,
                .foregroundColor: NSColor.secondaryLabelColor,
                .font: NSFont.systemFont(ofSize: 11, weight: .medium)
            ]
        )
        
        self.titleStackView.addArrangedSubview(NSView())
        self.titleStackView.addArrangedSubview(updateButton)
        self.updateButton.backgroundColor = .systemGray
        self.updateButton.snp.makeConstraints{ make in
            make.height.equalTo(18)
        }
        
        self.addArrangedSubview(typePicker)
        self.typePicker.setContentCompressionResistancePriority(.init(1), for: .horizontal)
        self.typePicker.spacing = 8
    }
}

final class ReposView: NSLoadView {
    let separator = NSBox() => { $0.boxType = .separator }
    let header = ReposHeader()
    let listViewPlaceholder = NSPlaceholderView()
    
    override func onAwake() {
        self.addSubview(header)
        self.header.snp.makeConstraints{ make in
            make.left.right.top.equalToSuperview()
        }

        self.addSubview(listViewPlaceholder)
        self.listViewPlaceholder.snp.makeConstraints{ make in
            make.top.equalTo(header.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
    }
    
}
