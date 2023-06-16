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
        NSAppleEventManager.shared()
            .setEventHandler(self, andSelector: #selector(handleGetURL(event:replyEvent:)),
                             forEventClass: AEEventClass(kInternetEventClass), andEventID: AEEventID(kAEGetURL))
    }

    @objc func handleGetURL(event: NSAppleEventDescriptor, replyEvent: NSAppleEventDescriptor) {
        guard let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue,
              let components = URLComponents(string: urlString),
              let urlComponent = components.queryItems?.first(where: { $0.name == "url" }),
              let repoURLString = urlComponent.value,
              let repoURL = URL(string: repoURLString)
        else {
            return NSSound.beep()
        }
        
        guard let model = NSApp.keyWindow?.contentViewController?.appSuccessModel else {
            Toast(message: "VCC is not loaded.").show()
            return NSSound.beep()
        }
        
        let alert = NSAlert()
        alert.messageText = "レポジトリ '\(repoURLString)' を VCC for mac に追加していいですか?"
        alert.informativeText = "レポジトリが VCC for mac に追加され、レポジトリに含まれるパッケージを利用できるようになります。"
        alert.addButton(withTitle: R.localizable.oK())
        alert.addButton(withTitle: R.localizable.cancel())
        if alert.runModal() == .alertFirstButtonReturn {
            model.addRepogitory(repoURL)
        }
        
    }
    func applicationDidBecomeActive(_ notification: Notification) {
        NSApp.windows.first?.contentViewController?.appModel.reloadPublisher.send()
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {        
        return true
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
    
    
}


extension _R {
    var localizable: string.localizable { self.string.localizable }
}
