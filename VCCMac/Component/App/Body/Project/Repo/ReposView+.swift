//
//  ReposView+.swift
//  VCCMac
//
//  Created by yuki on 2022/12/29.
//

import CoreUtil

enum RepoType: String, TextItem {
    case installed
    case official
    case curated
    case user
    
    var title: String {
        switch self {
        case .installed: return R.localizable.installed()
        case .official: return R.localizable.official()
        case .curated: return R.localizable.curated()
        case .user: return R.localizable.user()
        }
    }
}

final class ReposViewController: NSViewController {
    private let cell = ReposView()
    private let listViewController = ReposListViewController()
    
    override func loadView() {
        self.view = cell
        self.cell.listViewPlaceholder.contentView = listViewController.view
        self.addChild(listViewController)
    }
    
    override func chainObjectDidLoad() {
        self.appSuccessModelPublisher.map{ $0.$selectedRepo }.switchToLatest()
            .sink{[unowned self] in cell.header.typePicker.selectedItem = $0 }.store(in: &objectBag)
        
        self.cell.header.typePicker.itemPublisher
            .sink{[unowned self] in appSuccessModel?.selectedRepo = $0 }.store(in: &objectBag)
    }
}

final class ReposHeader: NSLoadStackView {
    let separator = NSBox() => { $0.boxType = .separator }
    let titleLabel = NSTextField(labelWithString: "")
    let typePicker = EnumSelectionBar<RepoType>()
    
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
        RepoType.allCases.forEach{ self.typePicker.addItem($0) }
        self.typePicker.spacing = 8
        self.typePicker.selectedItem = .official
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
//        self.addSubview(separator)
//        self.separator.snp.makeConstraints{ make in
//            make.left.right.equalToSuperview()
//            make.top.equalTo(header.snp.bottom)
//        }
        self.addSubview(listViewPlaceholder)
        self.listViewPlaceholder.snp.makeConstraints{ make in
            make.top.equalTo(header.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
    }
    
}
