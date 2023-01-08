//
//  ProjectNewView+.swift
//  VCCMac
//
//  Created by yuki on 2022/12/31.
//

import CoreUtil

final class ProjectTempleteSelectModel {
    @Observable var selectedTemplate: VPMTemplate?
    
    let projectManager: ProjectManager
    let command: VPMCommand
    let logger: Logger
    
    init(command: VPMCommand, projectManager: ProjectManager, logger: Logger) {
        self.projectManager = projectManager
        self.command = command
        self.logger = logger
    }
}

final class ProjectTempleteSelectWindow: ModalWindow {
    convenience init(model: ProjectTempleteSelectModel) {
        self.init(contentViewController: ProjectTempleteSelectViewController() => {
            $0.chainObject = model
        })
    }
}

final private class ProjectTempleteSelectViewController: NSViewController {
    private let cell = ProjectTempleteSelectView()
    private let listViewController = TemplateListViewController()
    private let noTemplateViewController = NoTemplateViewController()
    
    override func loadView() {
        self.addChild(listViewController)
        self.addChild(noTemplateViewController)
        
        self.cell.listPlaceholder.contentView = listViewController.view
        self.listViewController.noTempleteView = noTemplateViewController.view
        
        self.view = cell
    }
    
    override func chainObjectDidLoad() {
        cell.cancelButton.actionPublisher
            .sink{[unowned self] in self.view.window?.closeSheet(returnCode: .cancel) }.store(in: &objectBag)
        cell.okButton.actionPublisher
            .sink{[unowned self] in self.view.window?.closeSheet(returnCode: .OK) }.store(in: &objectBag)
        
        noTemplateViewController.needReloadPublisher
            .sink{[unowned self] in self.listViewController.reloadTempletes() }.store(in: &objectBag)
    }
}

final private class ProjectTempleteSelectView: NSLoadStackView {
    let titleLabel = H1Title(text: R.localizable.newProject())
    
    let listPlaceholder = NSPlaceholderView()
    
    private(set) lazy var buttonStack = NSStackView() => {
        $0.addArrangedSubview(NSView())
        $0.addArrangedSubview(cancelButton)
        $0.addArrangedSubview(okButton)
    }
    let okButton = Button(title: R.localizable.oK())
    let cancelButton = Button(title: R.localizable.cancel()) => {
        $0.backgroundColor = .systemGray
    }
    
    override func onAwake() {
        self.edgeInsets = .init(x: 16, y: 16)
        self.orientation = .vertical
        self.alignment = .left
        self.snp.makeConstraints{ make in
            make.width.equalTo(550)
            make.height.equalTo(400)
        }
        
        self.addArrangedSubview(titleLabel)
        self.addArrangedSubview(listPlaceholder)
        self.addArrangedSubview(buttonStack)
    }
}


extension NSWindow {
    func closeSheet(returnCode: NSApplication.ModalResponse) {
        self.sheetParent?.endSheet(self, returnCode: returnCode)
        self.close()
    }
}

final private class TemplateCell: NSLoadStackView {
    static let cellHeight: CGFloat = 64
    
    let iconView = ProjectTypeIcon()
    
    let titleLabel = NSTextField(labelWithString: "Title") => {
        $0.font = .systemFont(ofSize: 13, weight: .medium)
    }
    let pathLabel = NSTextField(labelWithString: "/path/to/templates") => {
        $0.font = .systemFont(ofSize: 10.5)
        $0.textColor = .secondaryLabelColor
        $0.lineBreakMode = .byTruncatingMiddle
    }
    
    override func onAwake() {
        self.orientation = .horizontal
        self.edgeInsets = .init(x: 8, y: 0)
        
        self.addArrangedSubview(iconView)
        
        let stackView = NSStackView()
        self.addArrangedSubview(stackView => { view in
            view.alignment = .left
            view.edgeInsets = .init(x: 8, y: 8)
            view.spacing = 4
            
            stackView.addArrangedSubview(titleLabel)
            stackView.addArrangedSubview(pathLabel)
        })
        self.pathLabel.snp.makeConstraints{ make in
            make.left.right.equalToSuperview().inset(8)
        }
    }
}


final private class TemplateListViewController: NSViewController {
    var noTempleteView: NSView!
    
    private let scrollView = NSScrollView()
    private let listView = EmptyImageTableView.list()
    private var loadingTemplates = true { didSet { updateListView() } }
    
    private var templates = [VPMTemplate]() {
        didSet { self.listView.reloadData() }
    }
    
    private func updateListView() {
        if self.loadingTemplates {
            self.listView.emptyView = NSTextField(labelWithString: R.localizable.loading()) => {
                $0.font = .systemFont(ofSize: 13)
                $0.textColor = .secondaryLabelColor
            }
        } else {
            self.listView.emptyView = noTempleteView
        }
    }
    
    override func loadView() {
        self.listView.delegate = self
        self.listView.dataSource = self
        self.listView.style = .inset
        self.scrollView.documentView = listView
        self.view = scrollView
        self.scrollView.snp.makeConstraints{ make in
            make.height.equalTo(TemplateCell.cellHeight * 4.5)
        }
        self.updateListView()
    }
    
    override func chainObjectDidLoad() {
        self.reloadTempletes()
    }
    
    func reloadTempletes() {
        guard let model = chainObject as? ProjectTempleteSelectModel else { return }
        self.loadingTemplates = true
        
        model.command.listTemplates().receive(on: .main)
            .peek{ templates in
                self.templates = templates
                if !templates.isEmpty {
                    self.listView.selectRowIndexes(.init(integer: 0), byExtendingSelection: false)
                }
            }
            .finally{
                self.loadingTemplates = false
            }
    }
}

extension TemplateListViewController: NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        templates.count
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        TemplateCell.cellHeight
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = TemplateCell()
        let templete = templates[row]
        
        cell.titleLabel.stringValue = templete.name
        cell.pathLabel.stringValue = templete.url.path
        cell.iconView.setProjectType(templete.projectType)
        
        return cell
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        guard let model = chainObject as? ProjectTempleteSelectModel else { return }
        
        model.selectedTemplate = templates.at(listView.selectedRow)
    }
}
