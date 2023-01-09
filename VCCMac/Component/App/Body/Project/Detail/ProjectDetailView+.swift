//
//  ProjectDetailView+.swift
//  VCCMac
//
//  Created by yuki on 2022/12/28.
//

import CoreUtil

final class ProjectDetailViewController: NSViewController {
    private let cell = ProjectDetailView()
    private let reposViewController = ReposContainerViewController()
    private var projectBag = Bag()
    
    override func loadView() {
        self.addChild(reposViewController)
        self.cell.reposPlaceholder.contentView = reposViewController.view
        self.view = cell
    }
    
    override func chainObjectDidLoad() {
        self.appSuccessModelPublisher.map{ $0.$selectedProject }.switchToLatest().compactMap{ $0 }
            .sink{[unowned self] in projectBag.removeAll(); self.updateProject($0, objectBag: &projectBag) }.store(in: &objectBag)
        
        self.appSuccessModelPublisher.map{ $0.$copyMigration }.switchToLatest().compactMap{ $0 }
            .sink{[unowned self] in self.cell.migrateInplaceSwitch.state = $0 ? .on : .off }.store(in: &objectBag)
        
        self.cell.migrateInplaceSwitch.actionPublisher
            .sink{[unowned self] in self.appSuccessModel?.copyMigration = self.cell.migrateInplaceSwitch.state == .on }
            .store(in: &self.objectBag)
        
        self.cell.header.menuButton.setActionHandler{
            guard let model = self.appSuccessModel, let project = model.selectedProject else { return [] }
            return model.makeProjectMenu(for: project)
        }
        
        self.cell.migrateButton.actionPublisher
            .sink{[unowned self] in self.migrateProject() }.store(in: &objectBag)
        self.cell.openButton.actionPublisher
            .sink{[unowned self] in self.openInUnity() }.store(in: &objectBag)
    }
        
    private func updateProject(_ project: Project, objectBag: inout Bag) {
        project.$title
            .sink{[unowned self] in cell.header.titleLabel.stringValue = $0 }.store(in: &objectBag)
        project.$projectURL
            .sink{[unowned self] in cell.header.pathLabel.stringValue = $0?.path ?? "Error" }.store(in: &objectBag)
        project.formattedDatep
            .sink{[unowned self] in cell.header.dateLabel.stringValue = $0 }.store(in: &objectBag)
        project.$projectType
            .sink{[unowned self] type in
                self.cell.header.typeLabel.isLoading = true
                self.cell.migratStackView.isHidden = true
                _ = type.peek{ self.updateProjectType($0) }
            }
            .store(in: &objectBag)
    }
    
    private func migrateProject() {
        guard let model = self.appSuccessModel, let project = model.selectedProject else { return NSSound.beep() }
        
        let toast = Toast(message: R.localizable.migratingProject())
        let label = toast.addSubtitleLabel("Start Migrating Project") => {
            $0.font = .monospacedSystemFont(ofSize: 10, weight: .regular)
        }
        toast.addSpinningIndicator()
        toast.show(.whileDeinit)
        
        let progress = PassthroughSubject<String, Never>()
        
        progress.receive(on: DispatchQueue.main).debounce(for: 0.03, scheduler: DispatchQueue.main)
            .sink{[unowned label] in label.stringValue = $0 }.store(in: &label.objectBag)
        
        model.projectManager.migrateProject(project, progress: progress, inplace: !model.copyMigration)
            .receive(on: .main)
            .peek{ toast.close() }
            .catch{ self.appModel.logger.error($0) }
    }
    
    private func openInUnity() {
        guard let model = self.appSuccessModel, let project = model.selectedProject else { return NSSound.beep() }
        
        model.projectManager.openInUnity(project, commandSettings: appModel.commandSetting)
            .receive(on: .main)
            .catch{ self.appModel.logger.error($0) }
    }
    
    private func updateProjectType(_ type: ProjectType) {
        cell.header.typeLabel.setProjectType(type)
        self.cell.migratStackView.isHidden = !type.isLegacy
    }
}

final private class ProjectDetailView: NSLoadVisualEffectView {
    let header = ProjectDetailHeaderView()
    
    let openButton = Button(title: R.localizable.openInUnity(), image: R.image.unity()) => {
        $0.imagePosition = .imageRight
    }
    let migrateButton = Button(title: R.localizable.migrateToVCC()) => {
        $0.backgroundColor = .systemGray
    }
    let migrateInplaceSwitch = NSSwitch()
    let migratStackView = NSStackView()
    let reposPlaceholder = NSPlaceholderView()
    
    private let stackView = NSStackView()
    
    override func onAwake() {
        self.material = .windowBackground
        self.snp.makeConstraints{ make in
            make.width.greaterThanOrEqualTo(240)
        }
        
        self.addSubview(stackView)
        self.stackView.snp.makeConstraints{ make in
            make.edges.equalToSuperview()
        }
        
        self.stackView.snp.makeConstraints{ make in
            make.top.left.right.equalToSuperview()
        }
        self.stackView.orientation = .vertical
        
        self.stackView.addArrangedSubview(header)
        self.header.snp.makeConstraints{ make in
            make.top.left.right.equalToSuperview()
        }
        
        self.stackView.addArrangedSubview(openButton)
        self.openButton.snp.makeConstraints{ make in
            make.width.equalToSuperview().inset(8)
        }
        
        self.stackView.addArrangedSubview(migratStackView  => {
            $0.orientation = .horizontal
            $0.addArrangedSubview(migrateButton => {
                $0.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            })
            $0.addArrangedSubview(NSTextField(labelWithString: "Copy"))
            $0.addArrangedSubview(migrateInplaceSwitch)
            self.migrateInplaceSwitch.snp.makeConstraints{ make in
                make.right.equalToSuperview()
            }
        })
        migratStackView.snp.makeConstraints{ make in
            make.left.right.equalToSuperview().inset(8)
        }
        
        self.stackView.addArrangedSubview(reposPlaceholder)
        self.reposPlaceholder.snp.makeConstraints{ make in
            make.right.left.bottom.equalToSuperview()
        }        
    }
}
