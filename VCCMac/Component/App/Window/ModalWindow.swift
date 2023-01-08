//
//  ModalWindow.swift
//  VCCMac
//
//  Created by yuki on 2023/01/02.
//

import CoreUtil

class ModalWindow: NSWindow {
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

