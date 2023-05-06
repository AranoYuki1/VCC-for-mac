//
//  VCCMacFileManager.swift
//  VCCMac
//
//  Created by yuki on 2022/12/27.
//

import Foundation

extension Bundle {
    static var appid: String {
        Bundle.main.bundleIdentifier ?? "com.yuki.unknown"
    }
}

enum AppFileManager {    
    static let rootURL = try! FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        .appendingPathComponent(Bundle.appid)
    
    static func makeDirectory(_ name: String) -> URL {
        let url = rootURL.appendingPathComponent(name)
        if !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }
}

extension URL {
    static let homeDirectory: URL = URL(fileURLWithPath: NSHomeDirectory())
}
