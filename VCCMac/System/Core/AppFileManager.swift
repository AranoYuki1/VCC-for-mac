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

final class AppFileManager {
    private let rootURL: URL
    
    init() throws {
        self.rootURL = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appending(component: Bundle.appid)
    }
    
    func makeDirectory(_ name: String) throws -> URL {
        let url = rootURL.appending(components: name)
        if !FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }
}
