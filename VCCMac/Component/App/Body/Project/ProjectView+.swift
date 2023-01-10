//
//  ProjectListView+.swift
//  VCCMac
//
//  Created by yuki on 2022/12/26.
//

import CoreUtil

final class ProjectContainerViewController: NSViewController {
    private let cell = NSPlaceholderView()
    private let projectViewController = ProjectViewController()
    private let requirementViewController = RequirementViewController()
    
    override func loadView() {
        self.addChild(projectViewController)
        self.addChild(requirementViewController)
        self.view = cell
    }
    
    override func chainObjectDidLoad() {
        appSuccessModelPublisher
            .sink{[unowned self] _ in self.cell.contentView = projectViewController.view }.store(in: &objectBag)
        
        appFailureModelPublisher
            .sink{[unowned self] _ in self.cell.contentView = requirementViewController.view }.store(in: &objectBag)
    }
}

final class ProjectViewController: NSViewController {
    private let cell = ProjectView()
    private let splitViewcontroller = ProjectSplitViewController()
    
    override func loadView() {
        self.addChild(splitViewcontroller)
        self.cell.bodyPlaceholder.contentView = splitViewcontroller.view
        self.view = cell
    }
    
    override func chainObjectDidLoad() {
        self.cell.header.openButton.actionPublisher
            .sink{[unowned self] in appSuccessModel?.modalOpenProject().catch{ self.appModel.logger.error($0) } }.store(in: &objectBag)
        self.cell.header.newButton.actionPublisher
            .sink{[unowned self] in appSuccessModel?.modalNewProject().catch{ self.appModel.logger.error($0) } }.store(in: &objectBag)
        self.cell.header.projectTypePicker.itemPublisher
            .sink{[unowned self] in self.appSuccessModel?.filterType = $0 }.store(in: &objectBag)
        self.cell.header.projectLegacyTypePicker.itemPublisher
            .sink{[unowned self] in self.appSuccessModel?.legacyFilterType = $0 }.store(in: &objectBag)
        self.cell.header.reloadButton.actionPublisher
            .sink{[unowned self] in self.appSuccessModel?.projectManager.reloadProjects().catch{ Toast(error: $0).show() } }.store(in: &objectBag)
        
        self.appSuccessModelPublisher.map{ $0.$filterType }.switchToLatest()
            .sink{[unowned self] in self.cell.header.projectTypePicker.selectedItem = $0 }.store(in: &objectBag)
        self.appSuccessModelPublisher.map{ $0.$legacyFilterType }.switchToLatest()
            .sink{[unowned self] in self.cell.header.projectLegacyTypePicker.selectedItem = $0 }.store(in: &objectBag)
    }
}

final private class ProjectView: NSLoadView {
    let header = ProjectHeaderView()
    let bodyPlaceholder = NSPlaceholderView()
    
    override func onAwake() {
        self.addSubview(header)
        self.header.snp.makeConstraints{ make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().inset(50)
        }
        
        self.addSubview(bodyPlaceholder)
        self.bodyPlaceholder.snp.makeConstraints{ make in
            make.top.equalTo(header.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
    }
}

final class ProjectSplitViewController: NSSplitViewController {
    private let listViewController = ProjectListViewController()
    private let detailViewController = ProjectDetailContainerViewController()
    
    override func viewDidLoad() {
        self.addSplitViewItem(NSSplitViewItem(contentListWithViewController: listViewController) => {
            $0.minimumThickness = 520
            $0.holdingPriority = .defaultLow
        })
        self.addSplitViewItem(NSSplitViewItem(viewController: detailViewController) => {
            $0.minimumThickness = 300
        })
        
        self.splitView.setPosition(400, ofDividerAt: 0)
        self.splitView.autosaveName = "project.split"
    }
    
    override func chainObjectDidLoad() {
        listViewController.chainObject = chainObject
        detailViewController.chainObject = chainObject
        
        self.linkState(of: .appSuccessModel, to: [listViewController, detailViewController])
        self.linkState(of: .appFailureModel, to: [listViewController, detailViewController])
    }
}
