//
//  MenuButton.swift
//  VCCMac
//
//  Created by yuki on 2022/12/29.
//

import CoreUtil

final class MenuButton: NSLoadButton {
    private var actionHandler: () -> ([NSMenuItem]) = { [] }
    
    func setActionHandler(_ handler: @escaping () -> ([NSMenuItem])) {
        self.actionHandler = handler
    }
    
    override func mouseDown(with event: NSEvent) {
        let menu = NSMenu()
        for item in actionHandler() { menu.addItem(item) }
        menu.popUp(positioning: nil, at: .zero, in: self)
    }
    
    override func onAwake() {
        self.snp.makeConstraints{ make in
            make.size.equalTo(28)
        }
        self.image = R.image.menu()
        self.title = ""
        self.isBordered = false
        self.imageScaling = .scaleProportionallyDown
        self.bezelStyle = .rounded
    }
}
