//
//  ProjectIOManager.swift
//  VCCMac
//
//  Created by yuki on 2023/01/02.
//

import CoreUtil

final class ProjectIOManager {
    static let encoder = JSONEncoder()
    static let decoder = JSONDecoder()
    
    private let containerDirectoryURL: URL
    private let command: VPMCommand
    private let manifestCoder: ProjectManifestCoder
    private let logger: Logger
    
    init(containerDirectoryURL: URL, command: VPMCommand, manifestCoder: ProjectManifestCoder, logger: Logger) {
        self.containerDirectoryURL = containerDirectoryURL
        self.command = command
        self.manifestCoder = manifestCoder
        self.logger = logger
    }
    
    func rename(_ projectURL: URL, name: String) -> Promise<Void, Error> {
        Promise.tryDispatch{
            let renamedURL = projectURL.deletingLastPathComponent().appendingPathComponent(name)
            try FileManager.default.moveItem(at: projectURL, to: renamedURL)
        }
    }
    
    func load(_ containerURL: URL, manager: ProjectManager) -> Promise<Project, Error> {
        Promise.tryDispatch{
            let linkURL = containerURL.appendingPathComponent(Project.projectLinkDirectoryName)
            let projectURL: URL
            do {
                projectURL = try URL(resolvingAliasFileAt: linkURL)
            } catch {
                self.logger.debug(error)
                throw ProjectError.loadFailed("Link not exists.")
            }
            
            return self.loadProject(at: projectURL, containerURL: containerURL, manager: manager)
                .mapError{ error in
                    self.logger.debug(error)
                    return ProjectError.loadFailed("\(error)")
                }
        }
        .flatMap{ $0 }
    }
    
    func new(_ projectURL: URL, manager: ProjectManager) -> Promise<Project, Error> {
        Promise.tryDispatch{[self] in
            guard FileManager.default.fileExists(atPath: projectURL.path) else {
                throw ProjectError.loadFailed("Project is not exists.")
            }
            
            let projectMeta = ProjectMeta(lastAccessDate: Date())
            let containerURL = containerDirectoryURL.appendingPathComponent(UUID().uuidString)
            let linkURL = containerURL.appendingPathComponent(Project.projectLinkDirectoryName)
            let metaURL = containerURL.appendingPathComponent(Project.projectMetaFileName)
                        
            do {
                try FileManager.default.createDirectory(at: containerURL, withIntermediateDirectories: true)
                try projectURL.createAlias(at: linkURL)
                try ProjectIOManager.encoder.encode(projectMeta).write(to: metaURL)
            } catch {
                logger.debug(error)
                throw ProjectError.loadFailed("Cannot Create Project Link.")
            }
                    
            return self.loadProject(at: projectURL, containerURL: containerURL, manager: manager)
                .peekError{ _ in try? FileManager.default.removeItem(at: containerURL) }
        }
        .flatMap{ $0 }
    }
    
    func updateAccessTime(_ project: Project) -> Promise<Void, Error> {
        Promise.tryDispatch{
            var meta = try ProjectIOManager.decoder.decode(ProjectMeta.self, from: Data(contentsOf: project.metaFileURL))
            meta.lastAccessDate = Date()
            project.accessDate = Date()
            try ProjectIOManager.encoder.encode(meta).write(to: project.metaFileURL)
        }
    }
    
    private func loadProject(at projectURL: URL, containerURL: URL, manager: ProjectManager) -> Promise<Project, Error> {
        Promise.tryDispatch{[self] in
            do {
                let metaURL = containerURL.appendingPathComponent(Project.projectMetaFileName)
                let meta = try Self.decoder.decode(ProjectMeta.self, from: Data(contentsOf: metaURL))
                
                let project = Project(
                    containerURL: containerURL,
                    accessDate: meta.lastAccessDate,
                    manifest: try manifestCoder.readManifest(at: projectURL),
                    projectType: command.getProjectType(at: projectURL),
                    projectManager: manager
                )
                
                return project
            } catch {
                throw ProjectError.loadFailed(error.localizedDescription)
            }
        }
    }
}

