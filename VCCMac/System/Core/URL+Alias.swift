//
//  AliasManager.swift
//  VCCMac
//
//  Created by yuki on 2022/12/30.
//

import Foundation

extension URL {
    func createAlias(at destURL: URL) throws {
        let data = try self.bookmarkData(options: .suitableForBookmarkFile, includingResourceValuesForKeys: nil, relativeTo: nil)
        try NSURL.writeBookmarkData(data, to: destURL, options: Int(URL.BookmarkCreationOptions.suitableForBookmarkFile.rawValue))
    }
}
