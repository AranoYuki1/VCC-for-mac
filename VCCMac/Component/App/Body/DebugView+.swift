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
        cell.showNekoButton.actionPublisher
            .sink{
                let toast = Toast(message: "ねこですよろしくおねがいします")
                let progress = Progress(totalUnitCount: 20)
                toast.addSpinningIndicator()
                let label = toast.addSubtitleLabel("Nya!")
                let colors = [
                    NSColor.clear, .systemRed, .systemGreen, .systemGreen, .systemBlue, .systemOrange, .systemYellow, .systemBrown, .systemPink, .systemPurple
                ].map{ $0.withAlphaComponent(0.2) }
                Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                    if progress.isFinished {
                        timer.invalidate(); toast.close()
                        Toast(message: "ねこでした。").show()
                    }
                    label.stringValue += "Nya!"
                    progress.completedUnitCount += 1
                    toast.color = colors[Int(progress.completedUnitCount) % colors.count]
                }
                
                toast.addSpinningProgressIndicator(progress)
                toast.addBarProgressIndicator(progress)
                toast.show(.whileDeinit)
            }
            .store(in: &objectBag)
        
        cell.openLogButton.actionPublisher
            .sink{ NSWorkspace.shared.open(self.appModel.loggerManager.logDirectoryURL) }
            .store(in: &objectBag)
        
        cell.exportLogButton.actionPublisher
            .sink{[unowned self] in exportLogFiles() }.store(in: &objectBag)
    }
    
    private func exportLogFiles() {
        do {
            let savePanel = NSSavePanel()
            savePanel.nameFieldStringValue = "\(Bundle.appid)_log.zip"
            guard savePanel.runModal() == .OK, let url = savePanel.url else { return }
            
            try FileManager.default.zipItem(at: self.appModel.loggerManager.logDirectoryURL, to: url)
        } catch {
            appModel.logger.error(error)
        }
    }
}

final private class DebugView: Page {
    let showNekoButton = Button(title: "🐱ねこ!", image: nil)
    let openLogButton = Button(title: "Open", image: nil)
    let exportLogButton = Button(title: "Export", image: nil)
    
    override func onAwake() {        
        self.addSection(
            Area(title: "Show Neko", control: showNekoButton)
        )
        self.addSection(
            Area(title: "Show Log Files", control: openLogButton)
        )
        self.addSection(
            Area(title: "Export Logs as Zip", control: exportLogButton)
        )
    }
}
