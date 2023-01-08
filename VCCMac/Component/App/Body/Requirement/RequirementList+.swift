//
//  RequirementList+.swift
//  VCCMac
//
//  Created by yuki on 2023/01/04.
//

import CoreUtil

final class RequirementListViewController: NSViewController {
    
    var reasons: [RequirementFailureReason] = [] {
        didSet {
            self.cell.removeAllCells()
            for reason in reasons { addCell(for: reason) }
        }
    }
    
    private let cell = RequirementListView()
    
    override func loadView() { self.view = cell }
    
    private func addCell(for reason: RequirementFailureReason) {
        let cell = RequirementCell()
        cell.title = reason.title
        cell.message = reason.message
        reason.setupHandler(cell)
        cell.isActive = reason.isRecoverable
        self.cell.addCell(cell)
    }
    
    override func chainObjectDidLoad() {
        self.appFailureModelPublisher
            .sink{[unowned self] model in
                self.reasons = model.reasons.map{ RequirementFailureReason.make(model: model, from: $0) }
            }
            .store(in: &objectBag)
    }
}

final class RequirementCell: NSLoadStackView {
    var title: String { get { titleLabel.stringValue } set { titleLabel.stringValue = newValue } }
    var message: String { get { messageLabel.stringValue } set { messageLabel.stringValue = newValue } }
    var isActive: Bool = true {
        didSet {
            self.alphaValue = isActive ? 1 : 0.3
            self.setIsEnabledAllControls(isActive)
        }
    }
    
    private let titleLabel = NSTextField(labelWithString: "") => {
        $0.font = .systemFont(ofSize: 15, weight: .medium)
    }
    
    private lazy var messageLabel = NSTextField(wrappingLabelWithString: "") => {
        $0.font = .systemFont(ofSize: 12)
        $0.textColor = .secondaryLabelColor
        $0.isSelectable = false
        self.addArrangedSubview($0)
    }
    private let backgroundLayer = ControlBackgroundLayer.animationDisabled()
    
    override func layout() {
        super.layout()
        self.backgroundLayer.frame = bounds
    }
    override func updateLayer() {
        self.backgroundLayer.update()
    }
    
    override func onAwake() {
        self.orientation = .vertical
        self.alignment = .left
        self.edgeInsets = .init(x: 16, y: 16)
        self.wantsLayer = true
        self.spacing = 12
        self.layer?.addSublayer(backgroundLayer)
        self.addArrangedSubview(titleLabel)
    }
}

final private class RequirementListView: NSLoadView {
    let listView = NSStackView()
    
    func addCell(_ cell: NSView) {
        self.listView.addArrangedSubview(cell)
        cell.snp.makeConstraints{ make in
            make.left.right.equalToSuperview()
        }
    }
    func removeAllCells() {
        self.listView.arrangedSubviews.forEach{
            $0.removeFromSuperview()
        }
    }
    
    override func onAwake() {
        self.addSubview(listView)
        self.listView.snp.makeConstraints{ make in
            make.edges.equalToSuperview()
        }
        
        self.listView.edgeInsets = NSEdgeInsets(x: 16, y: 16)
        self.listView.orientation = .vertical
    }
}

extension NSView {
    func setIsEnabledAllControls(_ isEnabled: Bool) {
        for subview in self.subviews {
            if let control = subview as? NSControl { control.isEnabled = isEnabled }
            subview.setIsEnabledAllControls(isEnabled)
        }
    }
}
