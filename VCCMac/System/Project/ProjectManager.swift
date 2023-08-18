//
//  ProjectManager.swift
//  VCCMac
//
//  Created by yuki on 2022/12/26.
//

import CoreUtil

final class ProjectManager {
    @Observable private(set) var projects = [Project]()
    @Observable private(set) var isReloading = false
    
    let containerDirectoryURL: URL
    
    private let command: VPMCommand
    private let logger: Logger
    private let manifestCoder: ProjectManifestCoder
    
    private let projectChecker: ProjectChecker
    private let projectIOManager: ProjectIOManager
    private let backupManager: ProjectBackupManager
    private let managerQueue = DispatchQueue(label: "com.yuki.projectmanager")
    
    init(command: VPMCommand, containerDirectoryURL: URL, manifestCoder: ProjectManifestCoder, logger: Logger) {
        self.command = command
        self.containerDirectoryURL = containerDirectoryURL
        self.logger = logger
        self.manifestCoder = manifestCoder
        self.projectChecker = .init(manifestCoder: manifestCoder, logger: logger)
        self.projectIOManager = .init(containerDirectoryURL: containerDirectoryURL, command: command, manifestCoder: manifestCoder, logger: logger)
        self.backupManager = .init()
        
        _ = self.reloadProjects()
    }
    
    func openInUnity(_ project: Project, commandSettings: VCCCommandSetting) -> Promise<Void, Error> {
        guard let projectURL = project.projectURL else { return .reject(ProjectError.projectOpenFailed) }
        let unityURL = URL(fileURLWithPath: commandSettings.pathToUnityExe)
        let catalyst = UnityCatalyst(executableURL: unityURL, logger: self.logger)
        let unityCommand = UnityCommand(catalyst: catalyst)
        
        return self.projectIOManager.updateAccessTime(project)
            .peek{ self.updateProjectSort() }
            .flatMap{ unityCommand.openProject(at: projectURL) }
    }
    
    func migrateProject(_ project: Project, progress: PassthroughSubject<String, Never>, inplace: Bool) -> Promise<Void, Error> {
        project.projectType
            .tryFlatMap{[self] projectType in
                guard projectType.isLegacy else { return .reject(ProjectError.migrateFailed("Not a Legacy Project.")) }
                guard let projectURL = project.projectURL else { return .reject(ProjectError.migrateFailed("Project not found.")) }
             
                if inplace {
                    return self.migrateProjectInplace(project, projectURL: projectURL, progress: progress)
                } else {
                    return self.migrateProjectCopy(project, projectURL: projectURL, progress: progress)
                }
            }
    }
    
    private func migrateProjectInplace(_ project: Project, projectURL: URL, progress: PassthroughSubject<String, Never>) -> Promise<Void, Error> {
        return command.migrateProject(at: projectURL, progress: progress, inplace: true)
            .flatMap{ project.reload() }
            .eraseToVoid()
    }
    
    private func migrateProjectCopy(_ project: Project, projectURL: URL, progress: PassthroughSubject<String, Never>) -> Promise<Void, Error> {
        let baseDirectoryURL = projectURL.deletingLastPathComponent()
        let migratedProjectBasename = projectURL.lastPathComponent + "-Migrated"
        
        func findMigratedProject() -> String {
            var index = 1
            var filename = migratedProjectBasename
            while FileManager.default.fileExists(at: baseDirectoryURL.appendingPathComponent(filename)) {
                index += 1
                filename = "\(migratedProjectBasename)-\(index)"
            }
            return filename
        }
        
        let migratedProjectFilename = findMigratedProject()
        let migratedProjectURL = baseDirectoryURL.appendingPathComponent(migratedProjectFilename)
        
        return command.migrateProject(at: projectURL, progress: progress, inplace: false)
            .flatMap{ self.addProject(migratedProjectURL) }
            .eraseToVoid()
    }
    
    func addBackupProject(_ backupProjectURL: URL, unpackTo directoryURL: URL, unpackProgress: Progress) -> Promise<Void, Error> {
        assert(backupProjectURL.pathExtension == "zip")
        
        return self.backupManager.loadBackup(backupProjectURL, to: directoryURL, progress: unpackProgress)
            .flatPeek{ self.addProject($0) }
            .eraseToVoid()
    }
    
    func addProject(_ existingProjectURL: URL) -> Promise<Void, Error> {
        Promise{[self] in
            let project = try await projectIOManager.new(existingProjectURL, manager: self).value
            let result = projectChecker.check(project)
            do {
                try projectChecker.recoverIfPossible(project, result: result)
                
                if let duplicatedProject = self.projects.first(where: { $0.projectURL == project.projectURL }) {
                    try await projectIOManager.updateAccessTime(duplicatedProject).value
                    self.updateProjectSort()
                    throw ProjectError.loadFailed("Duplicated project added.")
                }
                
                self.projects.insert(project, at: 0)
            } catch {
                await self.unlinkProject(project).value
                throw error
            }
        }
    }
    
    func reloadProjects() -> Promise<Void, Error> {
        if self.isReloading { return .resolve() }
        
        self.isReloading = true
        
        return Promise{[self] in
            let containerURLs = try FileManager.default.contentsOfDirectory(at: containerDirectoryURL, includingPropertiesForKeys: nil)
            
            var projects = [Project]()
            var projectURLs = Set<URL>()
            var errorCount = 0
            
            for containerURL in containerURLs {
                do {
                    let project = try await loadProject(at: containerURL).value
                    guard let projectURL = project.projectURL else { throw ProjectError.loadFailed("No project entity.") }
                    guard FileManager.default.isDirectory(projectURL) else { throw ProjectError.loadFailed("projectURL is not directory.") }
                    guard !projectURLs.contains(projectURL) else { throw ProjectError.loadFailed("Project already added.") }
                    projectURLs.insert(projectURL)
                    if projectURL.inTrash() { continue }
                    projects.append(project)
                } catch { // remove broken projects
                    await removeProject(containerURL).value
                    errorCount += 1
                    self.logger.debug(String(describing: error))
                }
            }
            
            self.projects = projects.sorted(by: { $0.accessDate > $1.accessDate })
            
            if errorCount != 0 {
                logger.error("\(errorCount) projects has errors & removed.")
            }
        }
        .peek{
            self.projects.map{ $0.projectType }.combineAll()
                .finally{ self.isReloading = false }
        }
    }
    
    func loadProject(at containerURL: URL) -> Promise<Project, Error> {
        projectIOManager.load(containerURL, manager: self)
    }
    
    func createProject(title: String, templete: VPMTemplate, at url: URL) -> Promise<Void, Error> {
        let projectURL = url.appendingPathComponent(title)
        return command.newProject(name: title, templete: templete, at: url)
            .flatMap{ self.projectIOManager.new(projectURL, manager: self) }
            .peek{ self.projects.insert($0, at: 0) }
            .eraseToVoid()
    }
    
    func unlinkProject(_ project: Project) -> Promise<Void, Never> {
        self.removeProject(project.containerURL)
            .peek{ self.projects.removeFirst(where: { $0 === project }) }
    }
    
    func renameProject(_ project: Project, to name: String) -> Promise<Void, Error> {
        guard let projectURL = project.projectURL else { return .reject(ProjectError.loadFailed("Project not found.")) }
        
        return self.projectIOManager.rename(projectURL, name: name)
            .flatMap{ project.reload() }
    }
    
    func backupProject(_ project: Project, to url: URL) -> Promise<Void, Error> {
        guard let projectURL = project.projectURL else { return .reject(ProjectError.loadFailed("Project not found.")) }
        guard url.pathExtension == "zip" else { return .reject(ProjectError.loadFailed("Backup must be zip.")) }
        return backupManager.makeBackup(projectURL, at: url)
    }
    
    private func updateAccessTime(_ project: Project) -> Promise<Void, Error> {
        projectIOManager.updateAccessTime(project)
    }
    
    private func updateProjectSort() {
        self.projects.sort(by: { $0.accessDate > $1.accessDate })
    }
    
    private func removeProject(_ containerURL: URL) -> Promise<Void, Never> {
        Promise.dispatch(on: managerQueue){
            do {
                try FileManager.default.removeItem(at: containerURL)
            } catch {
                self.logger.debug(error)
                self.logger.error("Remove Project Failed.")
            }
        }
    }
}

extension FileManager {
    public func fileExists(at url: URL) -> Bool {
        self.fileExists(atPath: url.path)
    }
    public func isDirectory(_ url: URL) -> Bool {
        var isDirectory = ObjCBool(false)
        fileExists(atPath: url.path, isDirectory: &isDirectory)
        return isDirectory.boolValue
    }
}

extension URL {
    func inTrash() -> Bool {
        guard let trashURL = FileManager.default.urls(for: .trashDirectory, in: .userDomainMask).first else {
            return false
        }
        
        return self.isContained(in: trashURL)
    }
}
