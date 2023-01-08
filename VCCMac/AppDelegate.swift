//
//  AppDelegate.swift
//  VCCMac
//
//  Created by yuki on 2022/12/21.
//

import Cocoa
import CoreUtil
import Rswift_mac


@main
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        NSApp.windows.first?.contentViewController?.appModel.reloadPublisher.send()
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}


extension _R {
    var localizable: string.localizable { self.string.localizable }
}
