//
//  DebugView+.swift
//  VCCMac
//
//  Created by yuki on 2022/12/21.
//

import AppKit
import CoreUtil

extension Promise {
    public static func asyncBlock<T>(_ block: @escaping () async -> (T)) -> Promise<T, Never> {
        let promise = Promise<T, Never>()
        
        Task.detached{
            let value = await block()
            promise.fullfill(value)
        }
        
        return promise
    }
}


final class __DebugViewController: NSViewController {
    private let cell = DebugView()
    
    override func loadView() { self.view = cell }
    
    override func chainObjectDidLoad() {
        cell.runButton.actionPublisher
            .sink{ self.runInstallCommand() }
            .store(in: &objectBag)
        
        runInstallCommand()
    }
    
    private func runInstallCommand() {
        
    }
}

final private class DebugView: Page {
    let runButton = Button(title: "Run", image: nil)
    
    override func onAwake() {
        self.addSection(
            Area(title: "Debug", control: runButton)
        )
    }
}
