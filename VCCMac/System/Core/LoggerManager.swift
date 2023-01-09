//
//  MakeLogger.swift
//  VCCMac
//
//  Created by yuki on 2023/01/02.
//

import CoreUtil

struct LoggerManagerError: LocalizedError {
    let errorDescription: String
    
    init(_ errorDescription: String) {
        self.errorDescription = errorDescription
    }
}

final class LoggerManager {
    let logDirectoryURL: URL
    let logFilename: String
    let maxLogCount: Int
    
    init(maxLogCount: Int) {
        self.maxLogCount = maxLogCount
        self.logDirectoryURL = LoggerManager.getLogDirectoryURL()
        self.logFilename = LoggerManager.makeUniqueLogFilename()
        
        self.cleanup()
    }
    
    func setup(_ logger: Logger) throws {
        let logFileURL = logDirectoryURL.appendingPathComponent(logFilename)
        if !FileManager.default.fileExists(at: logFileURL) {
            try Data().write(to: logFileURL)
        }
        
        let fileHandle = try FileHandle(forWritingTo: logFileURL)
        _ = try fileHandle.seekToEnd()
        logger.subscribe(minimumLevel: .debug, fileHandle: fileHandle)
    }
    
    private func cleanup() {
        do {
            let logFiles = try FileManager.default.contentsOfDirectory(at: logDirectoryURL, includingPropertiesForKeys: nil)
                .filter{ $0.pathExtension == "log" }
                .sorted(by: { $0.lastPathComponent })
                        
            if logFiles.count > maxLogCount {
                for i in 0..<logFiles.count-maxLogCount {
                    try? FileManager.default.removeItem(at: logFiles[i])
                }
            }
        } catch {
            print("Log cleanup failed.")
        }
    }
    
    private static func makeUniqueLogFilename() -> String {
        enum __ {
            static let formatter = DateFormatter() => {
                $0.dateFormat = "yyyy-MM-dd-HH-mm"
            }
            static let ltime = formatter.string(from: Date())
        }
        
        return "\(Bundle.appid) \(__.ltime).log"
    }
    
    private static func getLogDirectoryURL() -> URL {
        let fallbackDirectoryURL = URL.homeDirectory.appendingPathComponent("Library/Logs")
        guard let libraryURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first else {
            return fallbackDirectoryURL
        }
        
        let logDirectory = libraryURL.appendingPathComponent("Logs")
        let applicationLogDirectoryURL = logDirectory.appendingPathComponent(Bundle.appid)
        
        try? FileManager.default.createDirectory(at: applicationLogDirectoryURL, withIntermediateDirectories: true)
        
        guard FileManager.default.isDirectory(applicationLogDirectoryURL) else {
            return fallbackDirectoryURL
        }
        
        return applicationLogDirectoryURL
    }
}
