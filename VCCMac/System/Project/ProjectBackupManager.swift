//
//  ProjectBackupManager.swift
//  VCCMac
//
//  Created by yuki on 2023/01/02.
//

import CoreUtil
import ZIPFoundation

enum BackupError: Error, CustomStringConvertible {
    case loadFailed(String)
    
    var description: String {
        switch self {
        case .loadFailed(let string): return "Load failed (\(string))"
        }
    }
}

final class ProjectBackupManager {
    func makeBackup(_ projectURL: URL, at url: URL) -> Promise<Void, Error> {
        Promise.tryDispatch{
            try FileManager.default.zipItem(at: projectURL, to: url)
        }
    }
    
    private let temporaryDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent("unpacking_backup")
    
    func loadBackup(_ backupURL: URL, to url: URL, progress: Progress) -> Promise<URL, Error> {
        Promise.tryDispatch{
            let unpackDirectory = self.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            
            try FileManager.default.createDirectory(at: unpackDirectory, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: unpackDirectory) }
            
            try FileManager.default.unzipItem(at: backupURL, to: unpackDirectory, progress: progress)
            
            let contents = try FileManager.default.contentsOfDirectory(at: unpackDirectory, includingPropertiesForKeys: nil)
            
            guard contents.count == 1 else { throw BackupError.loadFailed("Multiple content unpacked.") }
            
            let projectURL = contents[0]
            let projectTitle = projectURL.lastPathComponent
            let destinationURL = url.appendingPathComponent(projectTitle)
            
            try FileManager.default.moveItem(at: projectURL, to: destinationURL)
            
            return destinationURL
        }
    }
}
