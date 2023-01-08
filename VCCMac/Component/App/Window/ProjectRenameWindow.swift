//
//  ProjectRenameView.swift
//  VCCMac
//
//  Created by yuki on 2023/01/02.
//

import CoreUtil

final class ProjectRenameModel {
    @Observable var title: String
    let project: Project
    
    init(project: Project) {
        self.project = project
        self.title = project.title
    }
}

final class ProjectRenameWindow: ModalWindow {
    convenience init(model: ProjectRenameModel) {
        self.init(contentViewController: ProjectRenameViewController() => {
            $0.chainObject = model
        })
    }
    override func cancelOperation(_ sender: Any?) {
        self.closeSheet(returnCode: .cancel)
    }
    override func keyDown(with event: NSEvent) {
        switch event.hotKey {
        case .return, .enter:
            self.closeSheet(returnCode: .OK)
        default:
            super.keyDown(with: event)
        }
    }
}


final private class ProjectRenameViewController: NSViewController {
    private let cell = ProjectRenameView()
    
    override func loadView() { self.view = cell }
    
    override func chainObjectDidLoad() {
        let model = chainObject as! ProjectRenameModel
        
        model.project.$projectURL
            .sink{[unowned self] in cell.pathLabel.stringValue = $0?.path ?? "Error" }.store(in: &objectBag)
        model.$title
            .sink{[unowned self] in cell.textField.string = $0 }.store(in: &objectBag)
        model.$title
            .sink{[unowned self] in cell.okButton.isEnabled = !$0.isEmpty }.store(in: &objectBag)
        
        cell.textField.changeStringPublisher
            .sink{ model.title = $0 }.store(in: &objectBag)
        
        cell.okButton.actionPublisher
            .sink{[unowned self] in self.view.window?.closeSheet(returnCode: .OK) }.store(in: &objectBag)
        
        cell.cancelButton.actionPublisher
            .sink{[unowned self] in self.view.window?.closeSheet(returnCode: .cancel) }.store(in: &objectBag)
    }
}

final private class ProjectRenameView: NSLoadStackView {
    let titleLabel = H2Title(text: R.localizable.renameProject())
    let pathLabel = NSTextField(labelWithString: "path/to/project") => {
        $0.font = .systemFont(ofSize: 11)
        $0.textColor = .secondaryLabelColor
    }
    let textField = TextField()
    let okButton = Button(title: R.localizable.oK())
    let cancelButton = Button(title: R.localizable.cancel()) => {
        $0.backgroundColor = .systemGray
    }
    private lazy var buttonStack = NSStackView() => {
        $0.addArrangedSubview(NSView())
        $0.addArrangedSubview(cancelButton)
        $0.addArrangedSubview(okButton)
    }
    
    override func onAwake() {
        self.snp.makeConstraints{ make in
            make.width.equalTo(300)
        }
        self.edgeInsets = .init(x: 16, y: 16)
        self.orientation = .vertical
        self.spacing = 12
        self.alignment = .left
        
        self.addArrangedSubview(titleLabel)
        self.addArrangedSubview(pathLabel)
        self.addArrangedSubview(textField)
        self.addArrangedSubview(buttonStack)
        
        self.pathLabel.lineBreakMode = .byTruncatingMiddle
        self.pathLabel.snp.makeConstraints{ make in
            make.left.right.equalToSuperview().inset(16)
        }
        
        self.textField.getTextField().actionPublisher
            .sink{[unowned self] in self.window?.closeSheet(returnCode: .OK) }
            .store(in: &objectBag)
        
        self.textField.placeholder = R.localizable.projectName()
    }
}
