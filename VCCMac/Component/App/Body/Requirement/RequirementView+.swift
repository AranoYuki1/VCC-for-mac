//
//  RequirementView+.swift
//  VCCMac
//
//  Created by yuki on 2023/01/03.
//

import CoreUtil

final class RequirementViewController: NSViewController {
    private let cell = RequirementView()
    private let listViewController = RequirementListViewController()
    
    override func loadView() {
        self.addChild(listViewController)
        self.cell.listViewPlaceholder.contentView = listViewController.view
        self.view = cell
    }
    
    override func chainObjectDidLoad() {
        
    }
}

final private class RequirementView: Page {
    let note = NoteView(type: .alert) => {
        $0.title = R.localizable.vccForMacIsNotAvailable()
        $0.message = R.localizable.vccForMacIsNotAvailableMessage()
    }
    
    let listViewPlaceholder = NSPlaceholderView()

    override func onAwake() {
        self.addSection(note)
        self.addSection(Paragraph(text: R.localizable.doTheFollowingFixesTitle()))
        self.addSection(listViewPlaceholder)
    }
}
