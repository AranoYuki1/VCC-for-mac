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
                let progress = Progress(totalUnitCount: 10)
                toast.addSpinningIndicator()
                let label = toast.addSubtitleLabel("Nya!")
                let colors = [
                    NSColor.clear, .systemRed, .systemGreen, .systemGreen, .systemBlue, .systemOrange, .systemYellow, .systemBrown, .systemPink, .systemPurple
                ].map{ $0.withAlphaComponent(0.2) }
                Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                    if progress.isFinished {
                        timer.invalidate();
                        if toast.isCurrentToast { Toast(message: "ねこでした。").show() }
                        toast.close()
                    }
                    label.stringValue += "Nya!"
                    progress.completedUnitCount += 1
                    toast.color = colors[Int(progress.completedUnitCount) % colors.count]
                }
                
                toast.addSpinningProgressIndicator(progress)
                toast.addBarProgressIndicator(progress)
                toast.addCloseButton().actionPublisher
                    .sink{ Toast(message: "ねこじゃないの?").show() }
                    .store(in: &self.objectBag)
                toast.show(.whileDeinit)
            }
            .store(in: &objectBag)
        
        cell.openLogButton.actionPublisher
            .sink{ NSWorkspace.shared.open(self.appModel.loggerManager.logDirectoryURL) }
            .store(in: &objectBag)
        
        cell.exportLogButton.actionPublisher
            .sink{[unowned self] in exportLogFiles() }.store(in: &objectBag)
        
        cell.clearLogButton.actionPublisher
            .sink{[unowned self] in clearLogFiles() }.store(in: &objectBag)
    }
    
    private func clearLogFiles() {
        do {
            let files = try FileManager.default.contentsOfDirectory(at: self.appModel.loggerManager.logDirectoryURL, includingPropertiesForKeys: nil)
            
            for file in files {
                _ = NSWorkspace.shared.recyclePromise([file], playSoundEffect: true)
            }
        } catch {
            appModel.logger.error(error)
        }
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
    let clearLogButton = Button(title: "Clear", image: nil)
    
    override func onAwake() {        
        self.addSection2(
            Section(title: "Test", items: [
                Area(title: "Show Neko", message: "Show Neko Toast as Test of Toast", control: showNekoButton)
            ]),
            Section(title: "Log", items: [
                Area(icon: R.image.folder(), title: "Show Log Files", message: "Open log files directory.", control: openLogButton),
                Area(icon: R.image.export(), title: "Export Logs", message: "Export log files as zip.", control: exportLogButton),
                Area(icon: R.image.clear_circle(), title: "Clear Log files", message: "20 or more files automatically deleted.", control: clearLogButton)
            ])
        )
    }
}

extension NSWorkspace {
    public func recyclePromise(_ urls: [URL], playSoundEffect: Bool = false) -> Promise<[URL: URL], Error> {
        Promise{ resolve, reject in
            self.recycle(urls) { table, error in
                if let error = error {
                    reject(error)
                } else {
                    if playSoundEffect {
                        NSSound.dragToTrash?.play()
                    }
                    resolve(table)
                }
            }
        }
    }
}
