//
//  DebugView+.swift
//  VCCMac
//
//  Created by yuki on 2022/12/21.
//

import AppKit
import CoreUtil

final class __DebugViewController: NSViewController {
    private let cell = DebugView()
    
    override func loadView() { self.view = cell }
    
    override func chainObjectDidLoad() {
        cell.openFolderButton.actionPublisher
            .sink{[unowned self] in
                if let url = appSuccessModel?.projectManager.containerDirectoryURL {
                    NSWorkspace.shared.open(url)
                }
            }
            .store(in: &objectBag)
        
        cell.openLogButton.actionPublisher
            .sink{[unowned self] in
                NSWorkspace.shared.open(appModel.loggerManager.logDirectoryURL)
            }
            .store(in: &objectBag)
        
//        cell.installVPMButton.actionPublisher
//            .sink{[unowned self] in installVPM() }.store(in: &objectBag)
    }
    
    func shell(_ command: String) -> String {
        let task = Process()
        let pipe = Pipe()
        
        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", command]
        task.launchPath = "/bin/zsh"
        task.standardInput = nil
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)!
        
        return output
    }
}

final private class DebugView: Page {
    let openFolderButton = Button(title: "Open", image: nil)
    let openLogButton = Button(title: "Open", image: nil)
    let installVPMButton = Button(title: "Install", image: nil)
    
    override func onAwake() {        
        self.addSection(
            Area(title: "Project Folder", control: openFolderButton)
        )
        self.addSection(
            Area(title: "Log Folder", control: openLogButton)
        )
        self.addSection(
            Area(title: "Install VPM", control: installVPMButton)
        )
    }
}
