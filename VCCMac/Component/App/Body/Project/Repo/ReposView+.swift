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
    
    private func onRightClickMenu(_ view: NSView, repo: PackageManager.Repogitory) {
        let menu = NSMenu()
        
        menu.addItem(title: "Remove Repogitory") {[self] in
            self.appSuccessModel?.packageManager.removeRepogitory(repo.id)
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
    }
}

final class ReposHeader: NSLoadStackView {
    let separator = NSBox() => { $0.boxType = .separator }
    let titleLabel = NSTextField(labelWithString: "")
    let typePicker = SelectionBar()
    
    override func onAwake() {
        self.addSubview(separator)
        self.separator.snp.makeConstraints{ make in
            make.top.left.right.equalToSuperview()
        }
        self.edgeInsets = .init(x: 10, y: 12)
        self.orientation = .vertical
        self.alignment = .left
        self.addArrangedSubview(titleLabel)
        self.titleLabel.attributedStringValue = NSAttributedString(
            string: R.localizable.packages().uppercased(), attributes: [
                .kern: 2.5,
                .foregroundColor: NSColor.secondaryLabelColor,
                .font: NSFont.systemFont(ofSize: 11, weight: .medium)
            ]
        )
        
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
