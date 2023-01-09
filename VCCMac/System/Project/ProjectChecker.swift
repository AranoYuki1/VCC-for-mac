//
//  ProjectChecker.swift
//  VCCMac
//
//  Created by yuki on 2023/01/02.
//

import Foundation

final class ProjectChecker {
    let logger: Logger
    let manifestCoder: ProjectManifestCoder
    
    init(manifestCoder: ProjectManifestCoder, logger: Logger) {
        self.manifestCoder = manifestCoder
        self.logger = logger
    }
    
    enum Result: Equatable {
        case success
        case criticalError
        case metaFileNotFound
        case notAUnityProject(String)
    }
    
    func check(_ project: Project) -> Result {
        guard FileManager.default.fileExists(at: project.containerURL) else {
            logger.debug("No container")
            return .criticalError
        }
        guard FileManager.default.fileExists(at: project.linkURL) else {
            logger.debug("No link")
            return .criticalError
        }
        guard FileManager.default.fileExists(at: project.metaFileURL) else {
            logger.debug("No metaFile")
            return .metaFileNotFound
        }
        
        do {
            let projectURL = try URL(resolvingAliasFileAt: project.linkURL)
            
            guard FileManager.default.isDirectory(projectURL) else {
                return .notAUnityProject("Project is not a directory.")
            }
            let unityProjectResult = checkUnityProject(projectURL)
            guard unityProjectResult == Result.success else {
                return unityProjectResult
            }
        } catch {
            logger.debug("Error on destinationOfSymbolicLink \(error)")
            return .criticalError
        }
        return .success
    }
    
    private func checkUnityProject(_ projectURL: URL) -> Result {
        let assetsURL = projectURL.appendingPathComponent("Assets")
        let projectSettingsURL = projectURL.appendingPathComponent("ProjectSettings")
        let projectVersionURL = projectSettingsURL.appendingPathComponent("ProjectVersion.txt")
        
        guard FileManager.default.isDirectory(assetsURL) else { return .notAUnityProject("No 'Assets' directory.") }
        guard FileManager.default.isDirectory(projectSettingsURL) else { return .notAUnityProject("No 'ProjectSettings' directory.") }
        guard FileManager.default.fileExists(at: projectVersionURL) else { return .notAUnityProject("No 'ProjectVersion.txt' file.") }
        
        return .success
    }
    
    func recoverIfPossible(_ project: Project, result: Result) throws {
        switch result {
        case .success: return
        case .criticalError:
            throw ProjectError.loadFailed("Project load failed with critical error.")
        case .notAUnityProject(let message):
            throw ProjectError.loadFailed("Not a Unity project. (\(message))")
        case .metaFileNotFound:
            let metaFileURL = project.metaFileURL
            let projectMeta = ProjectMeta(lastAccessDate: Date())
            try ProjectIOManager.encoder.encode(projectMeta).write(to: metaFileURL)
        }
    }
}
