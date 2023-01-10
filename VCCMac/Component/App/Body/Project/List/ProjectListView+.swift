//
//  ProjectListView+.swift
//  VCCMac
//
//  Created by yuki on 2022/12/28.
//

import CoreUtil

final class ProjectListViewController: NSViewController {
    private let scrollView = ScrollView()
    private let listView = TableView.list()
    private let notationView = DropNotationView(title: R.localizable.dropProjectFolderHere())
    private let openButton = Button(title: R.localizable.openInFinder()) => {
        $0.backgroundColor = .systemGray
    }
    
    private var projects = [Project]() {
        didSet { listView.reloadData() }
    }
    
    override func loadView() { self.view = NSView() }
    
    override func viewDidLoad() {
        self.listView.style = .inset
        self.listView.delegate = self
        self.listView.dataSource = self
        self.listView.emptyView = notationView
        self.scrollView.documentView = listView

        self.view.addSubview(scrollView)
        self.scrollView.snp.makeConstraints{ make in
            make.edges.equalToSuperview()
        }
        
        notationView.addArrangedSubview(NSTextField(labelWithString: "or") => {
            $0.textColor = .secondaryLabelColor
            $0.font = .systemFont(ofSize: 13)
        })
        notationView.addArrangedSubview(openButton)
    }
    
    override func chainObjectDidLoad() {
        let projects = self.appSuccessModelPublisher.map{ $0.projectManager.$projects }.switchToLatest()
        let filter = self.appSuccessModelPublisher.map{ $0.$filterType }.switchToLatest()
        let legacyFilter = self.appSuccessModelPublisher.map{ $0.$legacyFilterType }.switchToLatest()
        
        projects.combineLatest(filter, legacyFilter).receive(on: DispatchQueue.main).map{ self.filtereProjects($0, $1, $2) }
            .flatMap{ $0.publisher() }
            .sink{[unowned self] in self.projects = $0 }
            .store(in: &objectBag)
        
        listView.deletePublisher
            .sink{[unowned self] in
                guard let model = appSuccessModel, let project = self.projects.at(listView.selectedRow) else { return }
                model.deleteProject(project)
            }
            .store(in: &objectBag)
        
        
        openButton.actionPublisher
            .sink{[unowned self] in appSuccessModel?.modalOpenProject().catch{ self.appModel.logger.error($0) } }
            .store(in: &objectBag)
                
        scrollView.dropPublisher
            .sink{[unowned self] in self.handleDrops(of: $0) }.store(in: &objectBag)
    }
    
    private func filtereProjects(_ projects: [Project], _ filter: ProjectFilterType, _ lfilter: ProjectLegacyFilterType) -> Promise<[Project], Never> {
        if filter == .all && lfilter == .all { return .fullfill(projects) }
        
        return Promise.combineAll(projects.map{ $0.projectType })
            .map{_ in
                projects.filter{
                    guard case let .fulfilled(type) = $0.projectType.state else { return false }
                    return filter.accepts(type) && lfilter.accepts(type)
                }
            }
            .replaceError(with: [])
    }
    
    private func handleDrops(of urls: [URL]) {
        urls.forEach{
            appSuccessModel?.addProject(at: $0)
        }
    }
    
    override func rightMouseDown(with event: NSEvent) {
        guard let model = appSuccessModel else { return }
        
        let location = event.location(in: self.view)
            
        guard let project = projects.at(listView.clickedRow) else { return NSSound.beep() }
        
        let menu = NSMenu()
        menu.items = model.makeProjectMenu(for: project)
        menu.popUp(positioning: nil, at: location, in: view)
    }
}

extension ProjectListViewController: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return projects.count
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return ProjectCell.cellHeight
    }
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let model = appSuccessModel else { return nil }
        
        let cell = ProjectCell()
        let project = projects[row]
        
        cell.menuButton.setActionHandler{
            model.makeProjectMenu(for: project)
        }
        
        project.$title
            .sink{[unowned cell] in cell.titleLabel.stringValue = $0 }.store(in: &cell.objectBag)
        project.$projectURL
            .sink{[unowned cell] in cell.pathLabel.stringValue = $0?.path ?? "Error" }.store(in: &cell.objectBag)
        project.formattedDatep
            .sink{[unowned cell] in cell.dateLabel.stringValue = $0 }.store(in: &cell.objectBag)
        project.$projectType
            .sink{[weak cell] type in
                guard let cell = cell else { return }
                cell.typeLabel.isLoading = true
                cell.iconView.isLoading = true
                _ = type.peek{
                    cell.typeLabel.setProjectType($0)
                    cell.iconView.setProjectType($0)
                }
            }
            .store(in: &cell.objectBag)
        
        
        return cell
    }
}

final private class ScrollView: NSLoadScrollView {

    let dropPublisher = PassthroughSubject<[URL], Never>()
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard let urls = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self]) as? [URL], urls.allSatisfy({ acceptable($0) }) else {
            return []
        }
        
        return .copy
    }
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let urls = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self]) as? [URL], urls.allSatisfy({ acceptable($0) }) else {
            return false
        }
        
        dropPublisher.send(urls)
        
        return true
    }
    
    override func onAwake() {
        self.registerForDraggedTypes([NSPasteboard.PasteboardType.fileURL])
    }
    
    private func acceptable(_ url: URL) -> Bool {
        FileManager.default.isDirectory(url) || url.pathExtension == "zip"
    }
}

final private class TableView: EmptyImageTableView {
    let deletePublisher = PassthroughSubject<Void, Never>()
        
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        switch event.hotKey {
        case .delete:
            deletePublisher.send()
            return true
        default: return false
        }
    }
}

extension ProjectListViewController {
    func tableViewSelectionDidChange(_ notification: Notification) {
        self.appSuccessModel?.selectedProject = self.projects.at(listView.selectedRow)
    }
}

extension Promise {
    public func replaceErrorWithNil() -> Promise<Output?, Never> {
        self.map{ $0 as Output? }.replaceError(with: nil)
    }
    
    public func replaceErrorWithNil<T>() -> Promise<Output, Never> where Output == Optional<T> {
        self.replaceError(with: nil)
    }
}
