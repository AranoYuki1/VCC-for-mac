//
//  ProjectMetadataManager.swift
//  VCCMac
//
//  Created by yuki on 2022/12/29.
//

import Foundation

enum ManifestError: Error, CustomStringConvertible {
    case readFailed
    case writeFailed
    
    var description: String {
        switch self {
        case .readFailed: return "Read manifest failed."
        case .writeFailed: return "Write manifest failed."
        }
    }
}

final class ProjectManifestCoder {
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    private let logger: Logger
    
    init(logger: Logger) { self.logger = logger }
    
    func readManifest(at projectURL: URL) throws -> ProjectManifest? {
        let manifestURL = projectURL.appending(component: "Packages/vpm-manifest.json")
        
        if !FileManager.default.fileExists(at: manifestURL) { // legacy
            return nil
        }
        
        do {
            let data = try Data(contentsOf: manifestURL)
            return try decoder.decode(ProjectManifest.self, from: data)
        } catch {
            logger.debug(String(describing: error))
            throw ManifestError.readFailed
        }
    }
    
    func writeManifest(_ manifest: ProjectManifest, projectURL: URL) throws {
        do {
            let manifestURL = projectURL.appending(component: "Packages/vpm-manifest.json")
            try encoder.encode(manifest).write(to: manifestURL)
        } catch {
            logger.debug(String(describing: error))
            throw ManifestError.writeFailed
        }
    }
}
