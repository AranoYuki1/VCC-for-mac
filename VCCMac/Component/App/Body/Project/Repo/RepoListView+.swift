//
//  RepoListView+.swift
//  VCCMac
//
//  Created by yuki on 2022/12/29.
//

import CoreUtil

final class ReposListViewController: NSViewController {
    private let scrollView = NSScrollView()
    private let listView = NSStackView()
    
    var packages = [Package]() { didSet { reloadData() } }
    
    override func loadView() {
        self.listView.orientation = .vertical
        self.scrollView.contentView = FlipClipView()
        self.scrollView.drawsBackground = false
        self.scrollView.automaticallyAdjustsContentInsets = false
        self.scrollView.documentView = listView
        self.scrollView.contentInsets.bottom = 8
        
        self.listView.snp.makeConstraints{ make in
            make.right.left.equalToSuperview()
        }
        
        self.view = scrollView
    }
    
    private func reloadData() {
        self.listView.arrangedSubviews.forEach{
            $0.removeFromSuperview()
        }
        for package in packages {
            if let cell = self.cellView(for: package) {
                self.listView.addArrangedSubview(cell)
                cell.snp.makeConstraints{ make in
                    make.left.right.equalToSuperview().inset(8)
                }
            }
        }
    }
    
    override func chainObjectDidLoad() {
        let repo = appSuccessModelPublisher.map{ $0.selectedRepo }.switchToLatest()
        repo
            .receive(on: DispatchQueue.main)
            .sink{ self.packages = $0.packages }
        .store(in: &objectBag)
    }
}

extension Publisher {
    func eraseToAnyError() -> some Publisher<Output, Error> {
        self.mapError{ $0 }
    }
}

extension ReposListViewController {
    private func cellView(for package: Package) -> NSView? {
        guard let project = self.appSuccessModel?.selectedProject else { return nil }
        
        let cell = PackageCell()
        
        package.$selectedVersion
            .sink{[unowned cell] version in
                cell.titleLabel.stringValue = version.displayName
                cell.identifierLabel.stringValue = version.name
                cell.descriptionLabel.stringValue = version.description
                cell.versionPicker.selectedMenuTitle = version.version
            }
            .store(in: &cell.objectBag)
        
        cell.versionPicker.menuItems = package.versions.map{ version in
            NSMenuItem(title: version.version, action: {
                package.selectedVersion = version
            })
        }
        
        cell.addButton.actionPublisher
            .sink{[unowned self] in
                guard let model = appSuccessModel else { return }
                
                cell.addButton.isEnabled = false

                let toast = Toast(message: R.localizable.addingPackage(package.displayName)) => {
                    $0.addSpinningIndicator()
                }
                toast.show(.whileDeinit)
                model.packageManager.addPackage(package.selectedVersion, to: project)
                    .receive(on: .main)
                    .peek{
                        toast.close()
                        Toast(message: R.localizable.packageAdded()).show()
                    }
                    .catch{ self.appModel.logger.error($0) }
                    .finally{ cell.addButton.isEnabled = true }
                    
            }
            .store(in: &cell.objectBag)
        
        cell.removeButton.actionPublisher
            .sink{[unowned self] in
                guard let model = appSuccessModel else { return }
                
                cell.removeButton.isEnabled = false
                
                let toast = Toast(message: R.localizable.removingPackage(package.displayName)) => {
                    $0.addSpinningIndicator()
                }
                toast.show(.whileDeinit)
                model.packageManager.removePackage(package, from: project)
                    .receive(on: .main)
                    .peek{
                        toast.close()
                        Toast(message: R.localizable.removedPackage()).show()
                    }
                    .catch{ self.appModel.logger.error($0) }
                    .finally{ cell.removeButton.isEnabled = true }
            }
            .store(in: &objectBag)
        
        project.installedp(package)
            .sink{[unowned cell] installed in
                cell.addButton.isHidden = installed
                cell.removeButton.isHidden = !installed
            }
            .store(in: &cell.objectBag)
        
        return cell
    }
}

private extension Project {
    func installedp(_ package: Package) -> some Publisher<Bool, Never> {
        self.$manifest.compactMap{ manifest in
            manifest?.locked.keys.contains(package.versions[0].name)
        }
    }
}

private extension Button {
    func setIsEnabled(_ value: Bool) {
        self.isEnabled = value
    }
}
